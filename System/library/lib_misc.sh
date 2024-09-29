#!/usr/bin/env bash
# File    : library/lib_misc.sh
# Brief   : Contains helper functions, e.g: printing status, checking cmds..
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
# Repo    : https://github.com/martin-rizzo/AIMan
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                    AIMan
#        A basic package management system for AI open source projects
#
#     Copyright (c) 2023-2024 Martin Rizzo
#
#     Permission is hereby granted, free of charge, to any person obtaining
#     a copy of this software and associated documentation files (the
#     "Software"), to deal in the Software without restriction, including
#     without limitation the rights to use, copy, modify, merge, publish,
#     distribute, sublicense, and/or sell copies of the Software, and to
#     permit persons to whom the Software is furnished to do so, subject to
#     the following conditions:
#
#     The above copyright notice and this permission notice shall be
#     included in all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#     TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE
#     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
#
# FUNCTIONS:
#   >echox()                  : Prints messages in different formats.
#   >message()                : Displays a regular message.
#   >error()                  : Displays an error message.
#   >fatal_error()            : Displays a fatal error message and stops the script.
#   >error_unrecognized_arg() : Displays an error for an unrecognized argument and stops the script.
#   >bug_report()             : Displays a fatal error caused by a bug and stops the script.
#   >trim()                   : Removes leading and trailing whitespace from a string.
#   >clone_repository()       : Clones a Git repository.
#   >enforce_constraints()    : Enforces command constraints.
#   >require_system_command() : Checks if a given command is available on the system.
#   >ask_confirmation()       : Prompts the user for confirmation.
#   >safe_chdir()             : Changes directory safely, stopping the script if unsuccessful.
#
#-----------------------------------------------------------------------------

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
#BLUE='\e[1;34m'
CYAN='\e[1;36m'
DEFAULT_COLOR='\e[0m'

# GLOBAL INTERNAL VAR
LIB_LOG_PADDING='   '


# Prints messages with different formats. If the format is not specified,
# the message will be printed like the echo command.
#
# Usage: echox [format] message
#
# Parameters:
#   format - Optional format for the message. Can be one of the following:
#     * check: shows the message in green with a checkmark symbol in front.
#     * wait: shows the message in brown with a dash symbol in front.
#     * info: shows the message in blue with a circle symbol in front.
#     * warn: shows the message in yellow with an exclamation symbol in front.
#     * error: shows the message in red with an X symbol in front.
#     * fatal: shows the message in blinking red with a double X symbol in front.
#
#   message - The message to be printed.
#
echox() {
    local format=$1
    local prefix suffix
    case "$format" in
        check) prefix="${LIB_LOG_PADDING}${GREEN}\xE2\x9C\x94${DEFAULT_COLOR} " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        wait ) prefix="${LIB_LOG_PADDING}${YELLOW}- " ; suffix="...${DEFAULT_COLOR}" ; shift ;;
        info ) prefix="${LIB_LOG_PADDING}${CYAN}\xE2\x93\x98  " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        warn ) prefix="${LIB_LOG_PADDING}${YELLOW}! " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        alert) prefix="${CYAN}[${YELLOW}WARNING${CYAN}]${DEFAULT_COLOR}: " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        error) prefix="${CYAN}[${RED}ERROR${CYAN}]${DEFAULT_COLOR}: " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        #fatal) prefix='\033[7;31m \xE2\x9C\x96\xE2\x9C\x96 ' ; suffix='\033[0m' ; shift ;;
    esac
    echo -e -n "$prefix" >&2
    echo    -n "$@"      >&2
    echo    -e "$suffix" >&2
}

# Display a regular message
message() {
    local message=$1
    shift
    if [[ "$message" ]]; then
        echo -e -n "${LIB_LOG_PADDING}${GREEN}>${DEFAULT_COLOR} $message" >&2
        while [[ $# -gt 0 ]]; do
            message=$1
            echo -e -n " $message" >&2
            shift
        done
    fi
    echo >&2
}

# Display an error message
error() {
    local message=$1
    echo -e "${CYAN}[${RED}ERROR${CYAN}]${RED} $message${DEFAULT_COLOR}" >&2
}

# Displays a fatal error message and exits the script with status code 1
fatal_error() {
    local error_message=$1
    error "$error_message"
    shift

    # print informational messages, if any were provided
    while [[ $# -gt 0 ]]; do
        local info_message=$1
        echo -e " ${CYAN}\xF0\x9F\x9B\x88 $info_message${DEFAULT_COLOR}" >&2
        shift
    done
    exit 1
}

# Function to display an error message for unrecognized arguments
# $@ - all the arguments that were not recognized
error_unrecognized_arguments() {
  echo "Error: Unrecognized argument(s):" "$@"
  exit 1
}

bug_report() {
    local bug_message=$1
    echo
    echox error "$bug_message"
    echox info  "This is likely caused by a bug in the code. Please report this issue to a developer so he or she can investigate and fix it."
    echo
    exit 1
}

trim() {
    local input=$1
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"
    echo "$input"
}

# Clones a Git repository
#
# Usage:
#   clone_repository <repository_url> <commit_hash> <directory>
#
# Parameters:
#   - repository_url : the URL of the Git repository to be cloned.
#   - commit_hash    : the commit hash or tag to check out.
#                      (if '-' then the HEAD of the main branch will be used)
#   - directory      : the directory where the repository will be cloned.
#
# Example:
#   clone_repository "https://github.com/example/my-project.git" "abcd1234" "/path/to/my-project"
#
clone_repository() {
    local repo=$1 hash=$2 directory=$3
    local previous_dir

    previous_dir=$(pwd)
    if [[ $repo == '' || $hash == '' || $directory == '' ]]; then
        fatal_error "Missing required parameters in clone_repository() function." \
                    "This is an internal error likely caused by a mistake in the code"
    fi

    git clone "$repo" "$directory"
    if [[ $hash != '' && $hash != '-' ]]; then
        safe_chdir "$directory"
        git reset --hard "$hash"
    fi
    safe_chdir "$previous_dir"
}

# Enforces command constraints and exits script with a fatal error if not met.
#
# Usage:
#   enforce_constraints [--project] [--no-project] [--no-params] - "$@"
#
# Options:
#   --no-params  : Indicates that no additional parameters should be provided.
#   --no-project : Indicates that no project name should be provided.
#   --project    : Indicates that a project name must be provided.
#   --installed  : Indicates that the provided project must be installed.
#   -            : End of options
#   "$@" = The arguments that were passed to the command.
#
# Example:
#   enforce_constraints --no-project --no-params - "$@"
#
enforce_constraints() {
    local no_params=false

    # iterate through all options
    while true; do
        case "$1" in

            # validate if a project name must be provided
            --project)
                [[ $PROJECT_NAME ]] \
                || fatal_error "The '$COMMAND_NAME' command requires a project name to be provided" \
                    "If the project is 'webui', you can run: ./$SCRIPT_NAME webui.$COMMAND_NAME" \
                    "To see a list of available projects, use: ./$SCRIPT_NAME list"
                ;;
            # validate if a project name must NOT be provided
            --no-project)
                [[ -z $PROJECT_NAME ]] \
                || fatal_error "The '$COMMAND_NAME' command cannot be applied to any project" \
                    "For more information on how to use the '$COMMAND_NAME' command, please try: ./$SCRIPT_NAME $COMMAND_NAME --help"
                ;;
            # validate if the project should already be installed
            --installed)
                is_project_installed "$PROJECT_NAME" \
                || fatal_error "The project '$PROJECT_NAME' is not installed" \
                    "To check which projects are installed, use: ./$SCRIPT_NAME list" \
                    "To install the project '$PROJECT_NAME', use: ./$SCRIPT_NAME $PROJECT_NAME.install"
                ;;
            # validate if NO additional parameters must be provided
            --no-params)
                no_params=true
                ;;
            # if the end of options ('-') is found, stop processing options
            -)
                shift
                break
                ;;
            # any other type of option is unknown
            *)
                bug_report "Unknown option passed to the enforce_constraints() function: $1"
                ;;
        esac
        shift
    done

    # validate that no more parameters are left if required (--no-params)
    if [[ $no_params == true ]]; then
        [[ -z "$*" ]] \
        || fatal_error "Parameter $1 unknown, this command does not support parameters" \
            "For more information on how to use the '$COMMAND_NAME' command, please try: ./$SCRIPT_NAME $COMMAND_NAME --help"
    fi
}



# Function that checks whether a given command is available in the system
# and prints an error message with installation instructions if it is not.
# Usage: ensure_command <command>
# Arguments:
#   - command: the name of the command to be checked.
#
require_system_command() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echox error "$cmd is not available!"
            echox "   you can try to install '$cmd' using the following command:"
            echox "   > sudo dnf install $cmd"
            echox
            exit 1
        else
            echox check "$cmd is installed"
        fi
    done
}

# Prompts the user for confirmation and returns a boolean value.
#
# Usage:
#   ask_confirmation <message> [<warning>]
#
# Parameters:
#   - message: the confirmation message to be displayed to the user.
#   - warning (optional): a warning message to be displayed before the confirmation prompt.
#
# Returns:
#   - true (0) if the user confirms, false (1) otherwise.
#
# Example:
#   if ask_confirmation "Do you want to continue?"; then
#       echo "Proceeding with operation."
#   else
#       echo "Operation cancelled."
#   fi
#
ask_confirmation() {
    local message=$1 alert=$2

    if [[ $alert ]]; then
        echox
        echox alert "$alert"
    fi
    echox
    read -p " - $message (y/n): " -n 1 -r ; echo ; echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Attempts to change directory.
#
# Usage:
#   safe_chdir <target_dir>
#
# Parameters:
#   - target_dir: the directory to change to.
#
# Example:
#   safe_chdir "/home/user/documents"
#
safe_chdir() {
    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        fatal_error "Failed to change directory to '$target_dir', the directory does not exist." \
                    "This could be due to a bug or a special situation that wasn't accounted for when generating the code."
    fi
    cd "$target_dir" &>/dev/null ||
        fatal_error "Failed to change directory to '$target_dir'."\
                    "This could be due to a bug or a special situation that wasn't accounted for when generating the code." \
                    "It's also possible that user '$USER' does not have sufficient permissions to access the directory."
}
