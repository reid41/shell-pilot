#!/bin/bash

# define some colors
txtreset=$(tput sgr0)
txtbold=$(tput bold)
txtred=$(tput setaf 1)
txtgreen=$(tput setaf 2)

# define some fancy symbols
checkmark=$(echo -e "\xE2\x9C\x94")
fancyx=$(echo -e "\xE2\x9C\x97")

# define some fancy colors
PASS="${txtbold}${txtgreen}${checkmark}${txtreset}"
FAIL="${txtbold}${txtred}${fancyx}${txtreset}"

fuzzy_match=0

function show_processing() {
    echo -ne "\033[92mProcessing...\033[0m\033[0K\r"
}

function clear_processing() {
    echo -ne "\033[0K\r"  # Clears the line
}

# Function to perform second level package version check
second_level_check() {
    local package=$1
    local os_type=$(uname -s)
    local pkg_infos version vendor pkg_name

    case "$os_type" in
        Darwin)
            show_processing
            if [[ $fuzzy_match -eq 1 ]]; then
                info=$(brew list --versions | grep -i "$package")
            else
                info=$(brew list --versions "$package")
            fi
            clear_processing
            # echo "info: $info"
            if [ -n "$info" ]; then
                # Assume the output is like "graphviz 10.0.1 harfbuzz 8.4.0"
                # We need to split this into individual packages and their versions
                while read -r line; do
                    # Split the line into pairs of package and version
                    set -- $line  # This splits the line into positional parameters
                    while [ $# -gt 0 ]; do
                        pkg_name=$1
                        version=$2
                        echo "${PASS} $pkg_name version $version"
                        shift 2  # Move past the next package/version pair
                    done
                done <<< "$info"
            else
                echo "${FAIL} Package $package not found on macOS."
            fi
            ;;

        Linux)
            local distro_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
            if [[ $distro_id =~ ^(centos|rhel|fedora)$ ]]; then
                show_processing
                if [[ $fuzzy_match -eq 1 ]]; then
                    pkg_infos=$(rpm -qa | grep -i "$package")
                else
                    pkg_infos=$(rpm -qa | grep -E "^${package}-[0-9]")
                fi
                clear_processing
                if [ -z "$pkg_infos" ]; then
                    echo "${FAIL} Package $package not found on $distro_id."
                    return
                fi
                for pkg in $pkg_infos; do
                    pkg_name=$(rpm -q --queryformat '%{NAME}\n' "$pkg")
                    version=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}\n' "$pkg")
                    vendor=$(rpm -qi "$pkg" | grep -i "Vendor" | awk -F': ' '{print $2}')
                    echo "${PASS} $pkg_name version $version, Vendor: $vendor"
                done
            else
                echo "${FAIL} Package management not supported for $distro_id."
                return
            fi
            ;;
        *)
            echo "${FAIL} OS not supported for package checks."
            return
            ;;
    esac
}

# Main version detection function
generic_version_detect() {
    local package=$1
    local output success version

    if command -v "$package" &> /dev/null; then
        show_processing
        sleep 0.2
        clear_processing
        for arg in --version -version version -V -v; do
            output=$($package $arg 2>&1 | head -n 1)
            success=$?
            version=$(echo "$output" | grep -Eo "([0-9]+\.)+[0-9]+")
            if [[ $success -eq 0 && -n "$version" ]]; then
                echo "${PASS} $package version $version"
                return
            fi
        done
    fi
    second_level_check "$package"
}