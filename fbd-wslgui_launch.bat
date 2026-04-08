@echo off
setlocal enabledelayedexpansion
REM FBD GUI Launcher for Windows
REM This launches the Python GUI in WSL with automatic X11 server setup

echo ================================
echo FBD Node Manager GUI
echo ================================
echo.

REM Check if WSL is installed
wsl --list >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: WSL is not installed or not available
    echo Please install WSL first: wsl --install
    pause
    exit /b 1
)

echo Checking for X11 server...
echo.

REM Set marker file path
set "VCXSRV_MARKER=%~dp0.vcxsrv_running"

REM Clean up stale marker if VcXsrv isn't actually running
if exist "%VCXSRV_MARKER%" (
    tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
    if not "%ERRORLEVEL%"=="0" (
        del "%VCXSRV_MARKER%" >nul 2>&1
    )
)

REM Check if VcXsrv is running
tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
if "%ERRORLEVEL%"=="0" (
    REM Check if marker file exists (indicates we started it with correct flags)
    if exist "%VCXSRV_MARKER%" (
        echo [OK] VcXsrv is running (started by this script)
        echo Verifying X11 connection...
        
        REM Quick test to verify -ac flag is working
        wsl -e bash -c "timeout 2 xset q >/dev/null 2>&1"
        if "%ERRORLEVEL%"=="0" (
            echo [OK] X11 connection verified
            echo.
            goto :launch_gui
        ) else (
            echo [!] X11 connection test failed - VcXsrv may have been restarted without -ac flag
            echo Restarting VcXsrv with correct settings...
            echo.
            taskkill /IM vcxsrv.exe /F >nul 2>&1
            timeout /t 2 /nobreak >nul
            del "%VCXSRV_MARKER%" >nul 2>&1
            goto :start_vcxsrv
        )
    )
    
    echo [!] VcXsrv is already running
    echo.
    echo VcXsrv must be started with '-ac' flag for WSL compatibility.
    echo.
    echo Options:
    echo   1. Restart VcXsrv with correct settings (recommended)
    echo   2. Continue with current VcXsrv (may fail if not configured correctly)
    echo   3. Stop VcXsrv and exit
    echo.
    set "vcxchoice="
    set /p "vcxchoice=Enter choice (1/2/3): "
    
    if "!vcxchoice!"=="" set "vcxchoice=1"
    
    if "!vcxchoice!"=="1" (
        echo.
        echo Stopping current VcXsrv instance...
        taskkill /IM vcxsrv.exe /F >nul 2>&1
        timeout /t 2 /nobreak >nul
        del "%VCXSRV_MARKER%" >nul 2>&1
        goto :start_vcxsrv
    ) else if "!vcxchoice!"=="2" (
        echo.
        echo [!] Continuing with existing VcXsrv instance...
        echo If connection fails, please restart this script and choose option 1.
        echo.
        
        REM Still check firewall even with existing instance
        echo Checking Windows Firewall...
        netsh advfirewall firewall show rule name="VcXsrv X11 Server (WSL)" >nul 2>&1
        if errorlevel 1 (
            echo [!] Warning: Firewall rule not found
            echo This may prevent WSL from connecting to VcXsrv.
            echo.
            set "fwchoice2="
            set /p "fwchoice2=Add firewall rule? (Y/N): "
            if "!fwchoice2!"=="" set "fwchoice2=N"
            if /i "!fwchoice2!"=="Y" (
                powershell -Command "Start-Process '%~dp0Add_Firewall_Rule.bat' -Verb RunAs" 2>nul
                timeout /t 2 /nobreak >nul
                pause
            )
        ) else (
            echo [OK] Firewall rule exists
        )
        echo.
        goto :launch_gui
    ) else if "!vcxchoice!"=="3" (
        echo.
        echo Stopping VcXsrv...
        taskkill /IM vcxsrv.exe /F >nul 2>&1
        del "%VCXSRV_MARKER%" >nul 2>&1
        echo Done.
        pause
        exit /b 0
    ) else (
        echo Invalid choice. Continuing with existing instance...
        goto :launch_gui
    )
)

REM Check if Xming is running
tasklist /FI "IMAGENAME eq xming.exe" 2>NUL | find /I /N "xming.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] Xming is running
    goto :launch_gui
)

echo [!] No X11 server is currently running
echo.

:start_vcxsrv
REM Try to find VcXsrv installation
set "VCXSRV_PATH="
if exist "C:\Program Files\VcXsrv\vcxsrv.exe" (
    set "VCXSRV_PATH=C:\Program Files\VcXsrv\vcxsrv.exe"
) else if exist "C:\Program Files (x86)\VcXsrv\vcxsrv.exe" (
    set "VCXSRV_PATH=C:\Program Files (x86)\VcXsrv\vcxsrv.exe"
) else if exist "%ProgramFiles%\VcXsrv\vcxsrv.exe" (
    set "VCXSRV_PATH=%ProgramFiles%\VcXsrv\vcxsrv.exe"
)

if defined VCXSRV_PATH (
    echo [OK] Found VcXsrv at: %VCXSRV_PATH%
    echo.
    echo Starting VcXsrv with optimal settings...
    echo.
    
    REM Start VcXsrv with correct parameters
    REM :0 = display number 0
    REM -ac = disable access control (required for WSL)
    REM -multiwindow = use multiple windows mode  
    REM -clipboard = enable clipboard integration
    REM -wgl = use Windows OpenGL
    REM -nowgl = alternative if wgl causes issues
    start "VcXsrv" "%VCXSRV_PATH%" :0 -ac -multiwindow -clipboard -wgl
    
    echo Waiting for VcXsrv to start...
    timeout /t 3 /nobreak >nul
    
    REM Verify it started
    tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo [OK] VcXsrv started successfully
        REM Create marker file to indicate we started it with correct flags
        echo Started by fbd-wslgui_launch.bat with -ac flag > "%VCXSRV_MARKER%"
        echo.
    ) else (
        echo [!] VcXsrv may not have started correctly
        echo Continuing anyway...
        echo.
    )
    
    REM Check Windows Firewall rule
    echo Checking Windows Firewall...
    netsh advfirewall firewall show rule name="VcXsrv X11 Server (WSL)" >nul 2>&1
    if errorlevel 1 (
        echo [!] Firewall rule not found
        echo.
        echo Windows Firewall may block WSL from connecting to VcXsrv.
        echo.
        echo Would you like to add a firewall rule now?
        echo   Y = Yes, add rule ^(requires administrator rights^)
        echo   N = No, continue anyway
        echo.
        set "fwchoice="
        set /p "fwchoice=Add firewall rule? (Y/N): "
        
        if "!fwchoice!"=="" set "fwchoice=N"
        
        if /i "!fwchoice!"=="Y" (
            echo.
            echo Opening firewall setup with administrator rights...
            echo Please click "Yes" when prompted for elevation.
            echo.
            powershell -Command "Start-Process '%~dp0Add_Firewall_Rule.bat' -Verb RunAs" 2>nul
            if errorlevel 1 (
                echo [!] Could not launch firewall setup
                echo Please run Add_Firewall_Rule.bat manually as administrator
            ) else (
                timeout /t 3 /nobreak >nul
                echo.
                echo ========================================
                echo IMPORTANT: VcXsrv needs to be restarted!
                echo ========================================
                echo After adding the firewall rule, VcXsrv must
                echo be restarted to accept connections from WSL.
                echo.
                echo Restarting VcXsrv now...
                echo.
                taskkill /IM vcxsrv.exe /F >nul 2>&1
                timeout /t 2 /nobreak >nul
                
                echo Starting VcXsrv with correct settings...
                start "VcXsrv" "%VCXSRV_PATH%" :0 -ac -multiwindow -clipboard -wgl
                timeout /t 3 /nobreak >nul
                
                tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
                if errorlevel 0 (
                    echo [OK] VcXsrv restarted successfully
                    REM Create marker file
                    echo Started by fbd-wslgui_launch.bat with -ac flag > "%VCXSRV_MARKER%"
                ) else (
                    echo [!] VcXsrv may not have restarted
                )
                echo.
                pause
            )
        ) else (
            echo.
            echo [!] Continuing without firewall rule...
            echo If connection fails, run: Add_Firewall_Rule.bat as administrator
            echo.
        )
    ) else (
        echo [OK] Firewall rule exists
        echo.
    )
    
    goto :launch_gui
)

REM VcXsrv not found, offer to download
echo [!] VcXsrv is not installed
echo.
echo VcXsrv is required to run GUI applications from WSL.
echo.
echo Options:
echo   1. Download and install VcXsrv (attempts automatic download)
echo   2. Open download page in browser (manual install with instructions)
echo   3. Cancel
echo.
set "choice="
set /p "choice=Enter choice (1/2/3): "

if "%choice%"=="" set "choice=3"

if "%choice%"=="1" (
    echo.
    echo Attempting to download VcXsrv installer from GitHub...
    echo (This may take a minute, file is ~10 MB)
    echo.
    
    REM Download VcXsrv installer from GitHub releases
    REM Project moved to: https://github.com/marchaesen/vcxsrv
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://github.com/marchaesen/vcxsrv/releases/latest/download/vcxsrv-64.installer.exe' -OutFile $env:TEMP\vcxsrv-installer.exe -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -MaximumRedirection 5; if ((Get-Item $env:TEMP\vcxsrv-installer.exe).Length -gt 1MB) { exit 0 } else { exit 1 } } catch { exit 1 }}" >nul 2>&1
    
    if exist "%TEMP%\vcxsrv-installer.exe" (
        for %%A in ("%TEMP%\vcxsrv-installer.exe") do set size=%%~zA
        
        if !size! GTR 1000000 (
            echo [OK] Downloaded successfully ^(!size! bytes^)
            echo.
            echo Running installer...
            echo Please follow the installation wizard.
            echo.
            
            REM Run installer
            "%TEMP%\vcxsrv-installer.exe"
            
            echo.
            echo After installation completes, please run this script again.
            del "%TEMP%\vcxsrv-installer.exe" 2>nul
            pause
            exit /b 0
        )
    )
    
    REM If we get here, download failed
    echo [!] Automatic download failed
    echo.
    echo Opening download page in your browser for manual installation...
    echo.
    start https://github.com/marchaesen/vcxsrv/releases/latest
    echo.
    echo ========================================
    echo MANUAL INSTALLATION STEPS:
    echo ========================================
    echo 1. In the browser window that just opened,
    echo    scroll down to "Assets" section
    echo 2. Download: vcxsrv-64.installer.exe
    echo    (approximately 10 MB)
    echo 3. Run the downloaded installer
    echo 4. Follow the installation wizard
    echo 5. After installation, run this script again
    echo ========================================
    echo.
    del "%TEMP%\vcxsrv-installer.exe" 2>nul
    pause
    exit /b 0
    
) else if "%choice%"=="2" (
    echo.
    echo Opening VcXsrv download page in your browser...
    echo.
    start https://github.com/marchaesen/vcxsrv/releases/latest
    echo.
    echo ========================================
    echo MANUAL INSTALLATION STEPS:
    echo ========================================
    echo 1. In the browser window that just opened,
    echo    scroll down to "Assets" section
    echo 2. Download: vcxsrv-64.installer.exe
    echo    (approximately 10 MB)
    echo 3. Run the downloaded installer
    echo 4. Follow the installation wizard
    echo 5. After installation, run this script again
    echo ========================================
    echo.
    pause
    exit /b 0
    
) else (
    echo.
    echo Cancelled.
    pause
    exit /b 0
)

:launch_gui

echo Launching FBD GUI in WSL...
echo.
echo Note: The GUI window should appear shortly.
echo       This window will remain open while the GUI is running.
echo       Close the GUI to return here.
echo.
echo ========================================
echo.

REM Set DISPLAY for WSL
set WSL_DISPLAY=:0

REM Try with Ubuntu-24.04 first, then fallback to default WSL
wsl -d Ubuntu-24.04 -e bash -c "cd /mnt/e/STORE/app2MULT/app_hns/app_fbd/fbd-wslgui && ./fbd-wslgui_run.sh" 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] Ubuntu-24.04 distribution not found, trying default WSL...
    echo.
    wsl -e bash -c "cd /mnt/e/STORE/app2MULT/app_hns/app_fbd/fbd-wslgui && ./fbd-wslgui_run.sh" 2>&1
)

echo.
echo GUI closed.
echo.

REM Check if VcXsrv is still running
tasklist /FI "IMAGENAME eq vcxsrv.exe" 2>NUL | find /I /N "vcxsrv.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo VcXsrv is still running in the background.
    echo You can close it from the system tray if needed.
) else (
    echo VcXsrv has stopped.
)
echo.
pause
