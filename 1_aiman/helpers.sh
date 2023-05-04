#!/usr/bin/env bash



# Function that allows printing messages with different formats.
# Usage: echoex [check|error|wait] <message>
# Arguments:
#   - check: shows the message in green with a checkmark symbol in front.
#   - error: shows the message in red with an X symbol in front.
#   - wait : shows the message in yellow with a dash symbol in front.
#   - message: the message to be displayed.
#
function echoex() {
    if [[ $1 == check ]]; then
        echo -e "\033[32m \xE2\x9C\x94 $2\033[0m"
    elif [[ $1 == warn ]]; then
        echo -e "\033[33m ! $2\033[0m"
    elif [[ $1 == error ]]; then
        echo -e "\033[31m x $2\033[0m"
    elif [[ $1 == wait ]]; then
        echo -e "\033[33m . $2...\033[0m"
    else
        echo -e "$1"
    fi
}

# Function to display an error message for unrecognized arguments
# $@ - all the arguments that were not recognized
error_unrecognized_arguments() {
  echo "Error: Unrecognized argument(s): $@"
  exit 1
}


load_app_info() {
    local module=$1
    local module_ name_ brief_ license_ repo_ hash_ description_
    local IFS=,
    while read -r module_ name_ brief_ license_ repo_ hash_ description_; do
        app_name=$name_ ; app_brief=$brief_ ; app_license=$license_
        app_repo=$repo_ ; app_hash=$hash_
        app_description=$description_
        if [[ $module_ == $module ]]; then
            return
        fi
    done < "1_aiman/modules.lst"  
    app_name=''
}


