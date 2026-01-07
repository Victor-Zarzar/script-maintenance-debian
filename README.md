# Debian/Ubuntu Maintenance Script

A comprehensive, modular automated maintenance script for Debian/Ubuntu systems that helps clean cache files, optimize storage, and keep your system running smoothly.

## Features

- **Modular Architecture**: Clean, organized code split into focused modules
- **System Updates**: Keep your system and packages up to date
- **APT Cache Cleaning**: Remove old package archives and cache
- **Snap & Flatpak Management**: Clean old versions and unused packages
- **NPM/NVM Cache Management**: Clean Node.js package manager caches
- **Bun Cache Cleaning**: Clean Bun install cache and logs
- **PNPM Cache Management**: Prune unused packages
- **Flutter/Dart/FVM Cache**: Clean Flutter development caches
- **Android Studio & Emulator**: Complete cache cleaning including Gradle info
- **System Cache Removal**: Clean user library caches and logs
- **Docker Cleanup**: Remove unused containers, images, and volumes
- **Old Kernel Removal**: Remove old kernel versions safely
- **Automatic Log Generation**: Detailed maintenance logs with timestamps

## Requirements

- Debian/Ubuntu or derivatives
- Terminal access
- Sudo privileges for system operations

## Project Structure

```
maintenance-debian/
├── maintenance.sh            # Main script with interactive menu
├── lib/                      # Modular components
│   ├── colors.sh             # Color definitions for output
│   ├── helpers.sh            # Helper functions (size calc, formatting, progress)
│   ├── system-update.sh      # System and package updates
│   ├── package-clean.sh      # APT, Snap, Flatpak cleaning
│   ├── node-clean.sh         # NPM, Bun, PNPM cleaning
│   ├── flutter-clean.sh      # Flutter/Dart/FVM cleaning
│   ├── android-clean.sh      # Android Studio & Emulator cleaning
│   ├── docker-clean.sh       # Docker cleanup
│   ├── system-clean.sh       # System caches, logs, temp files
│   └── storage-optimize.sh   # Storage optimization and kernels
└── README.md                 # This file
```

## Installation

Clone the repository or create the directory structure:

```bash
mkdir -p maintenance-debian/lib
cd maintenance-debian
```

Copy all the provided files to their respective locations, then make the main script executable:

```bash
chmod +x maintenance.sh
```

## Usage

Run the script:

```bash
./maintenance.sh
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
9. Clean Bun
10. Clean PNPM
11. Clean Flutter/Dart/FVM
12. Clean Android Studio
13. Clean Docker
14. Remove old kernels
15. Clean logs
16. Clean user caches
17. Clean temporary files
18. Clean PIP cache
19. Optimize databases
20. Verify system health
21. View action log
22. Exit

## What Gets Cleaned

### Package Management

- **APT Cache**: Downloaded .deb files and package archives (500 MB - 2 GB)
- **Snap**: Old disabled snap versions (1-3 GB)
- **Flatpak**: Unused runtimes and dependencies (500 MB - 1 GB)
- **Orphaned Packages**: Automatically remove no longer needed packages

### Development Tools

- **Android Studio & Emulator**: AVD caches, build caches, IDE caches, logs (5-8 GB)
- **Flutter/Dart/FVM**: Development tool caches and pub cache (500 MB - 2 GB)
- **Gradle**: Information provided (cleaned manually with `./gradlew cleanBuildCache`)

### Package Managers

- **NPM/NVM**: Node package manager caches (500 MB - 2 GB)
- **Bun**: Cache, logs, and temporary files (200 MB - 1 GB)
- **PNPM**: Store pruning (300 MB - 1 GB)
- **PIP**: Python package cache (200 MB - 500 MB)

### System Maintenance

- **System Logs**: Journal logs, rotated logs, old log files (500 MB - 2 GB)
- **User Caches**: Browser caches, thumbnails, trash (1-5 GB)
- **Temporary Files**: /tmp and /var/tmp cleanup
- **Old Kernels**: Remove old kernel versions keeping latest 2 (500 MB - 2 GB)
- **Docker**: Unused containers, images, volumes (1-10 GB)

## Bun Cleaning Details

The script performs comprehensive Bun cleaning:

- `~/.bun/install/cache` - Main install cache
- `~/.bun/install/global/cache` - Global package cache
- `~/.bun/logs` - Old log files (7+ days)

Bun's cache will be automatically rebuilt when you install packages again.

## Android Studio & Gradle Cleaning Details

The script performs comprehensive Android cleaning:

### Android Studio & Emulator

- `~/.android/avd/*/cache` - Individual AVD cache directories
- `~/.android/cache` - General Android cache
- `~/.android/build-cache` - Android build cache
- `~/.cache/Google/AndroidStudio*` - Android Studio cache
- `~/.local/share/Google/AndroidStudio*/caches` - IDE caches
- `~/.local/share/Google/AndroidStudio*/log` - Android Studio logs

### Gradle (Information Only)

The script provides information about Gradle cache size but doesn't automatically clean it. To clean Gradle safely:

```bash
# In your project directory
./gradlew cleanBuildCache
```

Or to clean all Gradle cache (will be rebuilt on next build):

```bash
rm -rf ~/.gradle/caches/*
```

## Safety Features

- The script creates a detailed log file in your home directory
- Each operation shows the amount of space freed
- You can run individual cleaning operations instead of full maintenance
- Smart handling of system directories with proper permission checks
- Gradle cache is only shown for information (not automatically cleaned)
- Old kernels removal keeps the latest 2 versions
- System restart is recommended after full maintenance

## Log Files

Log files are automatically created with timestamp:

```
~/debian_maintenance_YYYYMMDD_HHMMSS.log
```

View the log from the menu (option 21) or manually:

```bash
cat ~/debian_maintenance_*.log
```

## Space Savings

Typical space savings after running full maintenance:

- **APT cache**: 500 MB - 2 GB
- **Snap packages**: 1-3 GB
- **Flatpak**: 500 MB - 1 GB
- **Android Studio & Emulator**: 5-8 GB
- **Flutter/Dart/FVM**: 500 MB - 2 GB
- **System caches**: 1-5 GB
- **Logs**: 500 MB - 2 GB
- **Old kernels**: 500 MB - 2 GB
- **Docker**: 1-10 GB
- **Bun/NPM/PNPM**: 1-4 GB

**Total**: 10-40+ GB depending on usage

## Customization

### Adding New Cleaning Functions

1. Identify the correct module in `lib/`
2. Add your cleaning function
3. Update `maintenance.sh` to call your function
4. Add option to menu if needed

Example in `lib/node-clean.sh`:

```bash
clean_your_tool() {
    print_section "Cleaning Your Tool"

    if command -v yourtool &> /dev/null; then
        # Your cleaning logic here
        print_success "Tool cleaned"
    else
        print_info "Tool not found"
    fi

    log_action "Your tool cleaned"
}
```

### Creating New Modules

1. Create file in `lib/module-name.sh`
2. Add shebang and section comment
3. Create cleaning functions
4. Add source in `maintenance.sh`
5. Call functions in `run_full_maintenance()`

## Tips

- Run option **1** (Complete maintenance) monthly for optimal performance
- Use individual options for targeted cleaning
- Check the log file if any cleaning fails
- Some operations may require administrator password
- System restart recommended after full maintenance, especially after kernel removal

## Troubleshooting

If you encounter issues:

1. Check the log file for detailed error messages
2. Ensure you have a stable internet connection for updates
3. Make sure you have enough permissions (some operations require sudo)
4. Run individual cleaning operations to isolate problems
5. Some paths may not exist if tools aren't installed (this is normal)

### Common Issues

**Permission errors:**
Some operations may request administrator password.

**Bun cache rebuilding:**
After cleaning Bun cache, first install will rebuild the cache.

**Gradle rebuilding:**
After cleaning Gradle cache, first build will take longer as cache rebuilds.

**View detailed errors:**

```bash
cat ~/debian_maintenance_*.log
```

## Advantages of Modular Architecture

- **Maintainability**: Each module has a specific responsibility
- **Readability**: Smaller, focused files
- **Reusability**: Modules can be used independently
- **Scalability**: Easy to add new cleaning functions
- **Debugging**: Easier to find and fix issues
- **Organization**: Similar to macOS version structure

## Differences from macOS Version

- Package management (APT, Snap, Flatpak instead of Homebrew)
- Kernel management specific to Linux
- Different system paths and cache locations
- Journal log management with systemd
- No Time Machine snapshots

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## Author

Victor Zarzar

---

**Note**: This script is designed for personal use. Review the code before running and adjust according to your needs. Always ensure you have backups of important data before running maintenance scripts.
