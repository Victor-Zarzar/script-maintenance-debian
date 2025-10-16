# Debian/Ubuntu Maintenance Script

A comprehensive automated maintenance script for Debian and Ubuntu systems that helps clean cache files, optimize storage, and keep your system running smoothly.

## Features

- System package updates and upgrades
- Broken package fixes
- Orphaned package removal
- APT cache cleaning
- Snap and Flatpak optimization
- NPM/NVM/PNPM cache management
- Flutter/Dart/FVM cache cleaning
- Docker cleanup
- Old kernel removal (keeps latest 2)
- System and user cache cleaning
- Log management
- Database optimization
- System health verification
- Automatic log generation

## Requirements

- Debian/Ubuntu-based distribution
- Terminal access
- Sudo privileges for system operations

## Installation

Clone the repository:

```bash
git clone https://github.com/Victor-Zarzar/script-maintenance-debian
```

Navigate to the directory:

```bash
cd script-maintenance-debian
```

Make the script executable:

```bash
chmod +x debian_maintenance.sh
```

## Usage

Run the script:

```bash
./debian_maintenance.sh
```

The script will display an interactive menu with the following options:

1. Run complete maintenance
2. Update system packages
3. Fix broken packages
4. Remove orphaned packages
5. Clean APT cache
6. Clean Snap packages
7. Clean Flatpak
8. Clean NPM/NVM
9. Clean PNPM
10. Clean Flutter/Dart/FVM
11. Clean Docker
12. Remove old kernels
13. Clean logs
14. Clean user caches
15. Clean temporary files
16. Clean PIP cache
17. Optimize databases
18. Verify system health
19. View action log

## What Gets Cleaned

- **System Packages**: Updates and upgrades all system packages
- **Package Cache**: APT, Snap, Flatpak cache and old packages
- **Development Tools**: npm, pnpm, Flutter, Dart cache files
- **Old Kernels**: Removes old kernel versions (keeps 2 most recent)
- **System Logs**: Journal logs, rotated logs, old log files
- **User Cache**: Browser cache, thumbnails, trash, VS Code cache
- **Temporary Files**: /tmp, /var/tmp old files
- **Docker**: Unused containers, images, volumes, and build cache
- **Python**: PIP cache cleanup

## Safety

- The script creates a detailed log file in your home directory
- Each operation shows the amount of space freed
- You can run individual cleaning operations instead of full maintenance
- System restart is recommended after kernel updates
- Current kernel is always preserved

## Log Files

Log files are automatically created with timestamp:
```
~/debian_maintenance_YYYYMMDD_HHMMSS.log
```

## Additional Verification

After maintenance, you can run these commands for additional checks:

```bash
sudo fsck -fn /
sudo apt list --upgradable
sudo systemctl --failed
```
