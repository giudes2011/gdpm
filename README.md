# GDPM (GiuDes Package Manager)

GDPM is a simple command-line tool written in Shell-Script for managing software packages. It provides functionalities to download, extract, configure, compile, install, and uninstall packages from various sources.

## Features

- **Download Packages**: Supports downloading packages from Git repositories or direct URLs.
- **Extract Packages**: Handles various archive formats including `.tar.gz`, `.tar.xz`, `.tar.bz2`, and `.zip`.
- **Configuration**: Automatically runs configuration scripts if available.
- **Compilation**: Compiles the source code using `make`.
- **Installation**: Installs the compiled binaries and libraries.
- **Uninstallation**: Cleans up and removes installed packages.

## Usage

If it's your first time running GDPM, in the same directory as `gdpm.sh`, run:

```
chmod +x gdpm.sh
```

To use GDPM, run the following command in the terminal:

```
sudo ./gdpm.sh [--verbose|-v] [--list|-l] [--update|-u] [--check-update|-c] [--commands|-C] [--backup|-b] [--restore|-r] [--help|-h] <install|uninstall> <package_url> [configure_options]
```

### Arguments

- `--verbose, -v`:  Enable verbose output
- `--list, -l`:  List installed packages
- `--update, -u`:  Update the script
- `--check-update, -c`:  Check if an update is available
- `--commands, -C`:  List available commands
- `--backup, -b`:  Backup installed packages
- `--restore, -r`:  Restore packages from backup
- `--handle-warnings, -w`:  Handle warnings during operations
- `--help, -h`:  Show this help message
- `<install|uninstall>`: Specify whether to install or uninstall a package.
- `<package_url>`: The URL of the package to install or uninstall.
- `[configure_options]`: Optional configuration options for the package.

## Example

To install a package:

```
sudo ./gdpm.sh install https://example.com/package.tar.gz
```

To uninstall a package:

```
sudo ./gdpm.sh uninstall package_name
```

## Requirements

- Make utility
- Internet connection for downloading packages

## License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for more details.
