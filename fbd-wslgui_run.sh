#!/bin/bash
# FBD GUI Runner Script for WSL
# This script sets up the environment and launches the Python GUI

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Set DISPLAY for X11 forwarding to Windows
export DISPLAY=:0

# Check if DISPLAY is accessible
if ! timeout 2 xset q &>/dev/null; then
    echo "ERROR: Cannot connect to X11 server on DISPLAY=$DISPLAY"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Make sure VcXsrv or Xming is running on Windows"
    echo "  2. Check that it was started with '-ac' flag"
    echo "  3. Verify Windows Firewall allows VcXsrv"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if Python3 is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is not installed"
    echo ""
    echo "Install with: sudo apt update && sudo apt install python3 python3-tk"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if tkinter is available
if ! python3 -c "import tkinter" 2>/dev/null; then
    echo "ERROR: python3-tk is not installed"
    echo ""
    echo "Install with: sudo apt install python3-tk"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if requests module is available
if ! python3 -c "import requests" 2>/dev/null; then
    echo "WARNING: requests module is not installed"
    echo ""
    echo "Install with: pip3 install requests"
    echo ""
    echo "Continuing anyway (some features may not work)..."
    echo ""
fi

echo "Starting FBD GUI..."
echo ""

# Run the Python GUI application
python3 fbd_wslgui.py

# Capture exit code
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "GUI exited with error code: $EXIT_CODE"
    read -p "Press Enter to exit..."
fi

exit $EXIT_CODE
