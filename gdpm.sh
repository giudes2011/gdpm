#!/bin/bash

#              .___               
#     ____   __| _/_____   _____  https://github.com/giudes2011/gdpm
#    / ___\ / __ |\____ \ /     \ 
#   / /_/  > /_/ ||  |_> >  Y Y  \  simple package manager
#   \___  /\____ ||   __/|__|_|  /          for GNU/Linux
#  /_____/      \/|__|         \/           ver 0.3
#  

show_help() {
    echo -e "\033[0;32mUsage: sudo $0 [--verbose|-v] [--list|-l] [--autoreconf|-a] [--update|-u] [--check-update|-c] [--commands|-C] [--backup|-b] [--restore|-r] [--handle-warnings|-w] [--help|-h] <install|uninstall> <package_url> [configure_options]\033[0m"
    echo -e "\033[0;32mOptions:\033[0m"
    echo -e "\033[0;32m  --verbose, -v          Enable verbose output\033[0m"
    echo -e "\033[0;32m  --list, -l             List installed packages\033[0m"
    echo -e "\033[0;32m  --update, -u           Update the script\033[0m"
    echo -e "\033[0;32m  --check-update, -c     Check if an update is available\033[0m"
    echo -e "\033[0;32m  --commands, -C         List available commands\033[0m"
    echo -e "\033[0;32m  --backup, -b           Backup installed packages\033[0m"
    echo -e "\033[0;32m  --restore, -r          Restore packages from backup\033[0m"
    echo -e "\033[0;32m  --handle-warnings, -w  Handle warnings during operations\033[0m"
    echo -e "\033[0;32m  --autoreconf, -a       Enable extra autoreconf step, needed for some packages\033[0m"
    echo -e "\033[0;32m  --help, -h             Show this help message\033[0m"
}

list_commands() {
    echo -e "\033[0;32mAvailable commands:\033[0m"
    echo -e "\033[0;32m  install    Install a package from a URL\033[0m"
    echo -e "\033[0;32m  uninstall  Uninstall a package\033[0m"
}

check_dependencies() {
    local dependencies=("wget" "tar" "make")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "\033[0;31mError: $dep is not installed.\033[0m"
            exit 1
        fi
    done
}

clean_temp_files() {
    rm -rf "/tmp/$BUILD_DIR" "/tmp/$PACKAGE_NAME" "/tmp/$TAR_FILE"
}

check_update() {
    echo -e "\033[0;32mChecking for script updates...\033[0m"
    SCRIPT_URL="https://raw.githubusercontent.com/giudes2011/gdpm/refs/heads/main/gdpm.sh"
    TEMP_SCRIPT="/tmp/gdpm.sh"

    if wget -q --show-progress "$SCRIPT_URL" -O "$TEMP_SCRIPT"; then
        if [ -s "$TEMP_SCRIPT" ]; then
            if ! cmp -s "$TEMP_SCRIPT" "$0"; then
                echo -e "\033[0;32mAn update is available.\033[0m"
            else
                echo -e "\033[0;32mNo updates available.\033[0m"
            fi
            rm -f "$TEMP_SCRIPT"
        else
            echo -e "\033[0;32mNo updates available.\033[0m"
            rm -f "$TEMP_SCRIPT"
        fi
    else
        echo -e "\033[0;31mError: Failed to check for updates.\033[0m"
    fi
    exit 0
}

backup_packages() {
    PREFIX_DIR=$(echo "$CONFIGURE_OPTIONS" | grep -oP '(?<=--prefix=)[^\s]+')
    if [ -z "$PREFIX_DIR" ]; then
        PREFIX_DIR="/usr/local"
    fi
    echo -e "\033[0;32mBacking up installed packages from $PREFIX_DIR...\033[0m"
    tar -czf /tmp/installed_packages_backup.tar.gz "$PREFIX_DIR"
    echo -e "\033[0;32mBackup completed: /tmp/installed_packages_backup.tar.gz\033[0m"
    exit 0
}

restore_packages() {
    PREFIX_DIR=$(echo "$CONFIGURE_OPTIONS" | grep -oP '(?<=--prefix=)[^\s]+')
    if [ -z "$PREFIX_DIR" ]; then
        PREFIX_DIR="/usr/local"
    fi
    echo -e "\033[0;32mRestoring packages to $PREFIX_DIR from backup...\033[0m"
    if [ -f /tmp/installed_packages_backup.tar.gz ]; then
        tar -xzf /tmp/installed_packages_backup.tar.gz -C /
        echo -e "\033[0;32mRestore completed.\033[0m"
    else
        echo -e "\033[0;31mError: Backup file not found.\033[0m"
    fi
    exit 0
}

manage_logs() {
    LOG_DIR="/var/log/gdpm"
    mkdir -p "$LOG_DIR"
    mv "$ERROR_LOG" "$LOG_DIR/$(date +%Y%m%d_%H%M%S)_error.log"
}

handle_warnings() {
    echo -e "\033[0;33mThe following warnings were encountered:\033[0m"
    grep -E "warning:|obsolete|error:|fatal:" $ERROR_LOG | sort | uniq | while read -r line; do
        echo -e "\033[0;33m$line\033[0m"
    done
}

if [ -z "$1" ]; then
    show_help
    exit 1
fi

VERBOSE=false
HANDLE_WARNINGS=false

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    if [[ "$1" =~ ^-[^-]+$ ]]; then
        # Handle combined short options
        for (( i=1; i<${#1}; i++ )); do
            case "${1:i:1}" in
                v)
                    VERBOSE=true
                    ;;
                l)
                    echo -e "\033[0;32mInstalled packages:\033[0m"
                    ls /usr/local/bin
                    exit 0
                    ;;
                u)
                    echo -e "\033[0;32mUpdating script...\033[0m"
                    SCRIPT_URL="https://raw.githubusercontent.com/giudes2011/gdpm/refs/heads/main/gdpm.sh"
                    TEMP_SCRIPT="/tmp/gdpm.sh"
                    if wget -q --show-progress "$SCRIPT_URL" -O "$TEMP_SCRIPT"; then
                        if [ -s "$TEMP_SCRIPT" ]; then
                            mv "$TEMP_SCRIPT" "$0"
                            chmod +x "$0"
                            echo -e "\033[0;32mScript updated successfully.\033[0m"
                        else
                            echo -e "\033[0;31mError: Downloaded script is empty.\033[0m"
                            rm -f "$TEMP_SCRIPT"
                        fi
                    else
                        echo -e "\033[0;31mError: Failed to download script from $SCRIPT_URL.\033[0m"
                        echo -e "\033[0;31mPlease check if the server is running and the URL is correct.\033[0m"
                    fi
                    exit 0
                    ;;
                c)
                    check_update
                    ;;
                C)
                    list_commands
                    exit 0
                    ;;
                b)
                    backup_packages
                    ;;
                r)
                    restore_packages
                    ;;
                w)
                    HANDLE_WARNINGS=true
                    ;;
                h)
                    show_help
                    exit 0
                    ;;
                a)
                    AUTORECONF=true
                    ;;
                *)
                    echo -e "\033[0;31mInvalid option: -${1:i:1}\033[0m"
                    show_help
                    exit 1
                    ;;
            esac
        done
    else
        # Handle long options or single short options
        case $1 in
            --verbose | -v)
                VERBOSE=true
                ;;
            --list | -l)
                echo -e "\033[0;32mInstalled packages:\033[0m"
                ls /usr/local/bin
                exit 0
                ;;
            --update | -u)
                echo -e "\033[0;32mUpdating script...\033[0m"
                SCRIPT_URL="https://raw.githubusercontent.com/giudes2011/gdpm/refs/heads/main/gdpm.sh"
                TEMP_SCRIPT="/tmp/gdpm.sh"
                if wget -q --show-progress "$SCRIPT_URL" -O "$TEMP_SCRIPT"; then
                    if [ -s "$TEMP_SCRIPT" ]; then
                        mv "$TEMP_SCRIPT" "$0"
                        chmod +x "$0"
                        echo -e "\033[0;32mScript updated successfully.\033[0m"
                    else
                        echo -e "\033[0;31mError: Downloaded script is empty.\033[0m"
                        rm -f "$TEMP_SCRIPT"
                    fi
                else
                    echo -e "\033[0;31mError: Failed to download script from $SCRIPT_URL.\033[0m"
                    echo -e "\033[0;31mPlease check if the server is running and the URL is correct.\033[0m"
                fi
                exit 0
                ;;
            --check-update | -c)
                check_update
                ;;
            --commands | -C)
                list_commands
                exit 0
                ;;
            --backup | -b)
                backup_packages
                ;;
            --restore | -r)
                restore_packages
                ;;
            --handle-warnings | -w)
                HANDLE_WARNINGS=true
                ;;
            --help | -h)
                show_help
                exit 0
                ;;
            --autoreconf | -a)
                AUTORECONF=true
                ;;
            -*)
                echo -e "\033[0;31mInvalid option: $1\033[0m"
                show_help
                exit 1
                ;;
        esac
    fi
    shift
done
if [[ "$1" == '--' ]]; then shift; fi

COMMAND="$1"
shift

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[0;31mError: This script must be run as root.\033[0m"
    exit 1
fi

PACKAGE_URL="$1"
TAR_FILE=$(basename "$PACKAGE_URL")
PACKAGE_NAME="${TAR_FILE%.tar.*}"
PACKAGE_NAME="${PACKAGE_NAME%.zip}"
BUILD_DIR="$PACKAGE_NAME-build"
CONFIGURE_OPTIONS="${@:2}"
ERROR_LOG="/tmp/gdpm_error.log"
export FORCE_UNSAFE_CONFIGURE=1

rm -rf "/tmp/$BUILD_DIR" "/tmp/$PACKAGE_NAME" "/tmp/$TAR_FILE"
if [[ "$PACKAGE_URL" == *.git ]]; then
    rm -rf "/tmp/$PACKAGE_NAME"
fi

UNINSTALL_PKG=false
SAFE_CHECK=false
NO_CONFIGURE=false

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    tput civis
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf "[%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        tput cub 6
    done
    printf "    \b\b\b\b"
    tput cnorm
}

untar() {
    echo -e "\033[0;32mDownloading $PACKAGE_NAME...\033[0m"
    if [[ "$PACKAGE_URL" == *.git ]]; then
        start_time=$(date +%s%3N)
        if [ $VERBOSE = true ]; then
            git clone --depth 1 --progress "$PACKAGE_URL" "/tmp/$PACKAGE_NAME" 2>&1 | tee $ERROR_LOG
        else
            (git clone --depth 1 --progress "$PACKAGE_URL" "/tmp/$PACKAGE_NAME" > $ERROR_LOG 2>&1) & spinner
        fi
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
        echo "done in $elapsed seconds"
    else
        start_time=$(date +%s%3N)
        if [ $VERBOSE = true ]; then
            wget --progress=bar:force -O "/tmp/$TAR_FILE" "$PACKAGE_URL" 2>&1 | tee $ERROR_LOG
        else
            (wget --progress=bar:force -O "/tmp/$TAR_FILE" "$PACKAGE_URL" > $ERROR_LOG 2>&1) & spinner
        fi
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
        echo "done in $elapsed seconds"
        echo ''
        echo -e "\033[0;32mNow untarring...\033[0m"
        start_time=$(date +%s%3N)
        if [[ "$TAR_FILE" == *.tar.gz ]]; then
            if ! tar -xzf "/tmp/$TAR_FILE" -C /tmp; then
                echo -e "\033[0;31mError: Failed to extract package.\033[0m"
                exit 1
            fi
        elif [[ "$TAR_FILE" == *.tar.xz ]]; then
            if ! tar -xJf "/tmp/$TAR_FILE" -C /tmp; then
                echo -e "\033[0;31mError: Failed to extract package.\033[0m"
                exit 1
            fi
        elif [[ "$TAR_FILE" == *.tar.bz2 ]]; then
            if ! tar -xjf "/tmp/$TAR_FILE" -C /tmp; then
                echo -e "\033[0;31mError: Failed to extract package.\033[0m"
                exit 1
            fi
        elif [[ "$TAR_FILE" == *.zip ]]; then
            if ! unzip -q "/tmp/$TAR_FILE" -d /tmp; then
                echo -e "\033[0;31mError: Failed to extract package.\033[0m"
                exit 1
            fi
        else
            echo -e "\033[0;31mError: Unsupported file format.\033[0m"
            exit 1
        fi
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
        echo "done in $elapsed seconds"
    fi
}

compiler() {
    echo ''
    echo -e "\033[0;32mCompiling...\033[0m"
    start_time=$(date +%s%3N)
    if [ "$NO_CONFIGURE" = true ]; then
        cd "/tmp/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Failed to enter source directory.\033[0m"; exit 1; }
    else
        cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
    fi
    if [ "$VERBOSE" = true ]; then
        make -j$(nproc) -k 2>&1 | tee $ERROR_LOG
        wait $!
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
    else
        (make -j$(nproc) -k > $ERROR_LOG 2>&1) & spinner
        wait $!
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
    fi
    if (( $(echo "$elapsed < 0.25" | bc -l) )); then
        SAFE_CHECK=true
        echo ''
        echo -e "\033[0;33mWarning: Compilation took less than 0.25 seconds. Use the --verbose (or -v) option to see what (may) went wrong.\033[0m"
        echo 'It is optional to test the program if it exsists or not.'
    else
        echo "done in $elapsed seconds"
    fi
    if [ "$HANDLE_WARNINGS" = true ]; then
        handle_warnings
    fi
}

run_autoupdate() {
    if [ -f "configure.ac" ]; then
        echo -e "\033[0;32mRunning autoupdate... [3/4]\033[0m"
        local checksum_before=$(md5sum configure.ac | awk '{print $1}')
        if [ "$VERBOSE" = true ]; then
            autoupdate 2>&1 | tee $ERROR_LOG
        else
            (autoupdate > $ERROR_LOG 2>&1) & spinner
        fi
        if [ $? -ne 0 ]; then
            cat $ERROR_LOG
            echo -e "\033[0;31mError: autoupdate failed.\033[0m"
            exit 1
        fi
        local checksum_after=$(md5sum configure.ac | awk '{print $1}')
        if [ "$checksum_before" = "$checksum_after" ]; then
            echo -e "\033[0;33mWarning: autoupdate did not modify configure.ac\033[0m"
        fi
        if [ "$HANDLE_WARNINGS" = true ]; then
            handle_warnings
        fi
    else
        echo -e "\033[0;33mWarning: configure.ac not found. Skipping autoupdate.\033[0m"
    fi
}

run_libtoolize() {
    echo -e "\033[0;32mRunning libtoolize... [1/4]\033[0m"
    if [ "$VERBOSE" = true ]; then
        libtoolize --force --copy 2>&1 | tee $ERROR_LOG
    else
        (libtoolize --force --copy > $ERROR_LOG 2>&1) & spinner
    fi
    if [ $? -ne 0 ]; then
        cat $ERROR_LOG
        echo -e "\033[0;31mError: libtoolize failed.\033[0m"
        exit 1
    fi
    if [ "$HANDLE_WARNINGS" = true ]; then
            handle_warnings
    fi
}

run_aclocal() {
    echo -e "\033[0;32mRunning aclocal...    [2/4]\033[0m"
    if [ "$VERBOSE" = true ]; then
        aclocal --force -I m4 2>&1 | tee $ERROR_LOG
    else
        (aclocal --force -I m4 > $ERROR_LOG 2>&1) & spinner
    fi
    if [ $? -ne 0 ]; then
        cat $ERROR_LOG
        echo -e "\033[0;31mError: aclocal failed.\033[0m"
        exit 1
    fi
    if [ "$HANDLE_WARNINGS" = true ]; then
            handle_warnings
    fi
}

run_autoreconf() {
    echo -e "\033[0;32mRunning autoreconf... [4/4]\033[0m"
    if [ "$VERBOSE" = true ]; then
        autoreconf -fvi 2>&1 | tee $ERROR_LOG
    else
        (autoreconf -fvi > $ERROR_LOG 2>&1) & spinner
    fi
    if [ $? -ne 0 ]; then
        cat $ERROR_LOG
        echo -e "\033[0;31mError: autoreconf failed.\033[0m"
        exit 1
    fi
    if [ "$HANDLE_WARNINGS" = true ]; then
            handle_warnings
    fi
}

pre_conf() {
    if [ "$UNINSTALL_PKG" = true ]; then
        cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
    else
        cd "/tmp/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
    fi
    run_libtoolize
    run_aclocal
    run_autoupdate
    run_autoreconf
    if [ "$UNINSTALL_PKG" = true ]; then
        cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
    else
        cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
    fi
}

configure() {
    if [ "$UNINSTALL_PKG" = true ]; then
        cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
    else
        cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
    fi
    if [ -x "$CONFIGURE_SCRIPT" ]; then
        if [ "$AUTORECONF" = true ]; then
            pre_conf
        fi
        echo ''
        echo -e "\033[0;32mConfiguring $PACKAGE_NAME...\033[0m"
        if [ "$VERBOSE" = true ]; then
            "$CONFIGURE_SCRIPT" $CONFIGURE_OPTIONS 2>&1 | tee $ERROR_LOG
            wait $!
        else
            ("$CONFIGURE_SCRIPT" $CONFIGURE_OPTIONS > $ERROR_LOG 2>&1) & spinner
            wait $!
        fi
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
        if [ $? -ne 0 ]; then
            cat $ERROR_LOG
            echo -e "\033[0;31mError: Configuration failed.\033[0m"
            exit 1
        else
            echo "done in $elapsed seconds"
        fi
    elif [ -x "$CONFIG_SCRIPT" ]; then
        if [ "$AUTORECONF" = true ]; then
            pre_conf
        fi
        echo ''
        echo -e "\033[0;32mConfiguring $PACKAGE_NAME...\033[0m"
        if [ "$VERBOSE" = true ]; then
            "$CONFIG_SCRIPT" $CONFIGURE_OPTIONS 2>&1 | tee $ERROR_LOG
            wait $!
        else
            ("$CONFIG_SCRIPT" $CONFIGURE_OPTIONS > $ERROR_LOG 2>&1) & spinner
            wait $!
        fi
        end_time=$(date +%s%3N)
        elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
        if [ $? -ne 0 ]; then
            cat $ERROR_LOG
            echo -e "\033[0;31mError: Configuration failed.\033[0m"
            exit 1
        else
            echo "done in $elapsed seconds"
        fi
    elif [ -x $AUTOGEN_SCRIPT ]; then
        if [ "$UNINSTALL_PKG" = true ]; then
            cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
        else
            cd "/tmp/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
        fi
        if [ "$VERBOSE" = true ]; then
            $AUTOGEN_SCRIPT 2>&1 | tee $ERROR_LOG
            wait $!
        else
            ($AUTOGEN_SCRIPT > $ERROR_LOG 2>&1) & spinner
            wait $!
        fi
        if [ "$UNINSTALL_PKG" = true ]; then
            cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
        else
            cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
        fi
        configure
        wait $!
        if [ $? -ne 0 ]; then
            cat $ERROR_LOG
            echo -e "\033[0;31mError: Configuration failed.\033[0m"
            exit 1
        fi
    elif [ -x $BOOTSTRAP_SCRIPT ]; then
        if [ "$UNINSTALL_PKG" = true ]; then
            cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
        else
            cd "/tmp/$PACKAGE_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
        fi
        if [ "$VERBOSE" = true ]; then
            $BOOTSTRAP_SCRIPT 2>&1 | tee $ERROR_LOG
            wait $!
        else
            ($BOOTSTRAP_SCRIPT > $ERROR_LOG 2>&1) & spinner
            wait $!
        fi
        if [ "$UNINSTALL_PKG" = true ]; then
            cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
        else
            cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
        fi
        configure
        wait $!
        if [ $? -ne 0 ]; then
            cat $ERROR_LOG
            echo -e "\033[0;31mError: Configuration failed.\033[0m"
            exit 1
        fi
    else
        if [ "$UNINSTALL_PKG" = true ]; then
            cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
        else
            cd "/tmp/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
        fi
        echo -e "\033[0;33mWarning: No configure script found. Proceeding with default options.\033[0m"
        NO_CONFIGURE=true
    fi
}

install_package() {
    read -p "Proceed installation of: $PACKAGE_NAME? [Y/n]: " confirm
    confirm=${confirm,,} # tolower
    if [[ $confirm != "y" && $confirm != "yes" && $confirm != "" ]]; then
        echo -e "\033[0;31mInstallation aborted.\033[0m"
        exit 1
    fi
    echo ''
    untar
    if [ ! -d "/tmp/$PACKAGE_NAME" ]; then
        echo -e "\033[0;31mError: Extracted directory '/tmp/$PACKAGE_NAME' not found!\033[0m"
        exit 1
    fi

    mkdir -p "/tmp/$BUILD_DIR"
    cd "/tmp/$BUILD_DIR" || { echo -e "\033[0;31mError: Failed to enter build directory.\033[0m"; exit 1; }
    echo ''
    CONFIGURE_SCRIPT="../$PACKAGE_NAME/configure"
    CONFIG_SCRIPT="../$PACKAGE_NAME/config"
    AUTOGEN_SCRIPT="../$PACKAGE_NAME/autogen.sh"
    BOOTSTRAP_SCRIPT="../$PACKAGE_NAME/bootstrap"
    start_time=$(date +%s%3N)
    configure
    compiler
    echo ''
    echo -e "\033[0;32mInstalling...\033[0m"
    start_time=$(date +%s%3N)
    if [ "$VERBOSE" = true ]; then
        make install 2>&1 | tee $ERROR_LOG
        wait $!
    else
        (make install > $ERROR_LOG 2>&1) & spinner
        wait $!
    fi
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Installation failed.\033[0m"
        cat "$ERROR_LOG"
        exit 1
    fi
    end_time=$(date +%s%3N)
    elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
    if (( $(echo "$elapsed < 0.25" | bc -l) )); then
            echo ''
            echo -e "\033[0;33mWarning: Installation took less than 0.25 seconds. Use the --verbose (or -v) option to see what (may) went wrong.\033[0m"
            echo 'It is optional to test the program if it exsists or not.'
    fi
    echo "done in $elapsed seconds"
    echo ''
    echo -e "\033[0;32mFinishing installation...\033[0m"
    echo ''
    mkdir -p "$HOME/gdpm_packages/"
    cp -r "/tmp/$PACKAGE_NAME" "$HOME/gdpm_packages/"
    clean_temp_files
    manage_logs
    if [ "$SAFE_CHECK" = true ]; then
        echo -e "\033[0;34mInstallation of $PACKAGE_NAME not completed successfully.\033[0m"
        exit 1
    else
        echo -e "\033[0;34mInstallation of $PACKAGE_NAME completed successfully.\033[0m"
        exit 0
    fi
}

uninstall_package() {
    read -p "Uninstall: $PACKAGE_NAME? [Y/n]: " confirm
    confirm=${confirm,,} # tolower
    if [[ $confirm != "y" && $confirm != "yes" && $confirm != "" ]]; then
        echo -e "\033[0;31mAborted.\033[0m"
        exit 1
    fi
    echo ''
    echo -e "\033[0;32mUninstalling $PACKAGE_NAME...\033[0m"
    echo ''
    cd "$HOME/gdpm_packages/$PACKAGE_NAME" || { echo -e "\033[0;31mError: Not installed\033[0m"; exit 1; }
    CONFIGURE_SCRIPT="./configure"
    CONFIG_SCRIPT="./config"
    AUTOGEN_SCRIPT="./autogen.sh"
    BOOTSTRAP_SCRIPT="./bootstrap"
    start_time=$(date +%s%3N)
    UNINSTALL_PKG=true
    configure
    start_time=$(date +%s%3N)
    if [ "$VERBOSE" = true ]; then
        make clean 2>&1 | tee $ERROR_LOG
        wait $!
        make uninstall 2>&1 | tee $ERROR_LOG
        wait $!
    else
        (make clean > $ERROR_LOG 2>&1) & spinner
        wait $!
        (make uninstall > $ERROR_LOG 2>&1) & spinner
        wait $!
    fi
    end_time=$(date +%s%3N)
    elapsed=$(echo "scale=3; ($end_time - $start_time) / 1000" | bc)
    echo "done in $elapsed seconds"
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mError: Uninstallation failed.\033[0m"
        cat "$ERROR_LOG"
        exit 1
    fi
    cd ..
    clean_temp_files
    rm -rf "$HOME/gdpm_packages/$PACKAGE_NAME"
    manage_logs
    echo -e "\033[0;34mUninstallation of $PACKAGE_NAME completed successfully.\033[0m"
    exit 0
}

case "$COMMAND" in
    install)
        install_package
        ;;
    uninstall)
        uninstall_package
        ;;
    *)
        echo -e "\033[0;31mInvalid command. Usage: sudo $0 [--verbose|-v] [--list|-l] [--update|-u] [--check-update|-c] [--commands|-C] [--backup|-b] [--restore|-r] [--handle-warnings|-w] [--help|-h] <install|uninstall> <package_url> [configure_options]\033[0m"
        exit 1
        ;;
esac
