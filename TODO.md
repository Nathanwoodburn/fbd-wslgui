# FBD GUI - TODO List

## High Priority

### Binary Management & Version Checking
**Status:** Planned  
**Created:** April 8, 2026

Since `fbd` and `fbdctl` binaries are not included in the repository (due to file size), users must download and maintain them manually. This feature would automate that process.

**Requirements:**
- [ ] Check for presence of `fbd` and `fbdctl` binaries on app startup
- [ ] Detect current binary versions (if present)
- [ ] Check GitHub releases API for latest available version
- [ ] Display version comparison in UI (current vs. available)
- [ ] Provide download button/wizard to fetch latest binaries
- [ ] Auto-extract and set permissions (chmod +x)
- [ ] Optional: Periodic update checks (configurable frequency)
- [ ] Optional: Backup old binaries before updating

**Implementation Notes:**
- Download URL: `https://fbd.dev/download/fbd-latest-linux-x86_64.zip`
- Auto-extract zip and set permissions (chmod +x)
- Consider version checking endpoint if available
- Consider adding to Settings tab with "Check for Updates" button
- Add notification system for available updates

---

## Medium Priority

_Add future enhancements here_

---

## Low Priority / Ideas

_Add nice-to-have features here_
