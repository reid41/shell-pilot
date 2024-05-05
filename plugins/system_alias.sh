#!/usr/bin/env bash
base_system_alias_dir="$HOME/spilot_files_dir"
shell_pilot_alias_file=$base_system_alias_dir/shell_pilot_system_aliases

function shell_pilot_add_system_aliases() {
    [[ ! -d $base_system_alias_dir ]] && mkdir -p $base_system_alias_dir
    [[ ! -f $shell_pilot_alias_file ]] && touch $shell_pilot_alias_file

    # check if the number of arguments is even
    if (( $# % 2 != 0 )); then
        echo -e "\033[0;31m==> Warining: Incorrect number of arguments.\nPlease provide aliases and commands in pairs.\033[0m"
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        local alias_name="$1"
        local alias_command="$2"
        if grep -q "^alias $alias_name=" "$shell_pilot_alias_file"; then
            echo -e "==> Alias  \033[0;36m'$alias_name'\033[0m already exists in $shell_pilot_alias_file"
        else
            echo "alias $alias_name='$alias_command'" >> "$shell_pilot_alias_file"
            eval "alias $alias_name='$alias_command'"
            echo -e "==> Alias \033[0;36m'$alias_name'\033[0m added to $shell_pilot_alias_file and is active."
        fi
        shift 2 # Move to the next alias-command pair
    done
}


function shell_pilot_remove_system_aliases() {
    [[ ! -d $base_system_alias_dir ]] && mkdir -p $base_system_alias_dir
    [[ ! -f $shell_pilot_alias_file ]] && touch $shell_pilot_alias_file
    local os_type=$(uname -s)

    if (( $# == 0 )); then
        echo -e "\033[0;31m==> Warning: No aliases provided.\nPlease provide at least one alias name to remove.\033[0m"
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        local alias_name="$1"
        if grep -q "^alias $alias_name=" "$shell_pilot_alias_file"; then
            if [[ "$os_type" == "Darwin"* ]]; then
                sed -i "" "/^alias $alias_name=/d" "$shell_pilot_alias_file"
            else
                sed -i "/^alias $alias_name=/d" "$shell_pilot_alias_file"
            fi
            eval "unalias $alias_name"
            echo -e "==> Alias \033[0;36m'$alias_name'\033[0m removed from $shell_pilot_alias_file"
        else
            echo -e "==> Alias \033[0;36m'$alias_name'\033[0m does not exist in $shell_pilot_alias_file"
        fi
        shift # Move to the next alias name
    done
}

# list aliases from the system alias file
function shell_pilot_list_system_aliases() {
    [[ ! -d $base_system_alias_dir ]] && mkdir -p $base_system_alias_dir
    [[ ! -f $shell_pilot_alias_file ]] && echo -e "\033[0;31m==> Not create alias in $shell_pilot_alias_file\033[0m" && return

    if [[ -s $shell_pilot_alias_file ]]; then
        echo -e "\033[0;36m==> Aliase List:\033[0m"
       cat $shell_pilot_alias_file
    else
       echo -e "\033[0;36m==> No aliases found in $shell_pilot_alias_file\033[0m"
    fi
}