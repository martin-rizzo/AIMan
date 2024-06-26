#!/usr/bin/env bash
# File    : helpers/misc.sh
# Brief   : Contains helper functions, e.g: printing status, checking cmds..
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
# Repo    : https://github.com/martin-rizzo/AIAppManager
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
# TODO: reajustar lso formatos de 'echox' para igualarlos a otros proyectos
# TODO: completar el resumen de cada funcion en la lista de abajo
#
# FUNCTIONS:
#   - echox()                  : Prints messages with different formats.
#   - bug_report()             : ???
#   - fatal_error()            : ???
#   - error_unrecognized_arg() : Displays error message for unrecognized argument.
#   - trim()                   : ???
#   - clone_repository()       : Clones a Git repository.
#   - enforce_constraints()    : Enforce command constraints
#   - require_system_command() : Checks whether a given command is available in the system.
#   - ask_confirmation()       : Prompts the user for confirmation.
#
#-----------------------------------------------------------------------------

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
DEFAULT_COLOR='\e[0m'
PADDING='  '


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
function echox() {
    local format=$1
    local prefix suffix
    case "$format" in
        check) prefix="${PADDING}${GREEN}\xE2\x9C\x94${DEFAULT_COLOR} " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        wait ) prefix="${PADDING}${YELLOW}- " ; suffix="...${DEFAULT_COLOR}" ; shift ;;
        info ) prefix="${PADDING}${CYAN}\xE2\x93\x98  " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        warn ) prefix="${PADDING}${YELLOW}! " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        alert) prefix="${CYAN}[${YELLOW}WARNING${CYAN}]${DEFAULT_COLOR}: " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        error) prefix="${CYAN}[${RED}ERROR${CYAN}]${DEFAULT_COLOR}: " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        #fatal) prefix='\033[7;31m \xE2\x9C\x96\xE2\x9C\x96 ' ; suffix='\033[0m' ; shift ;;
    esac
    echo -e -n "$prefix"
    echo    -n "$@"
    echo -e    "$suffix"
}

function bug_report() {
    local bug_message=$1
    echo
    echox error "$bug_message"
    echox info  "This is likely caused by a bug in the code. Please report this issue to a developer so he or she can investigate and fix it."
    echo
    exit 1
}

function fatal_error() {
    local fatal_message=$1
    echo
    echox error "$fatal_message"
    shift
    for comment in "$@"; do
        echox info  "$comment"
    done
    echo
    exit 1
}

# Function to display an error message for unrecognized arguments
# $@ - all the arguments that were not recognized
function error_unrecognized_arguments() {
  echo "Error: Unrecognized argument(s): $@"
  exit 1
}

function trim() {
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
function clone_repository() {
    local repo=$1 hash=$2 directory=$3
    local previous_dir=$(pwd)

    if [[ $repo == '' || $hash == '' || $directory == '' ]]; then
        fatal_error "Missing required parameters in clone_repository() function." \
                    "This is an internal error likely caused by a mistake in the code"
    fi

    git clone "$repo" "$directory"
    if [[ $hash != '' && $hash != '-' ]]; then
        cd "$directory"
        git reset --hard "$hash"
    fi
    cd "$previous_dir" &> /dev/null
}

# Enforces command constraints and exits script with a fatal error if not met.
#
# Usage:
#   enforce_constraints [--project] [--no-project] [--no-params] "$@"
#
# Options:
#   --no-params  : Indicates that no additional parameters should be provided.
#   --no-project : Indicates that no project name should be provided.
#   --project    : Indicates that a project name must be provided.
#   --installed  : Indicates that the provided project must be installed.
#   "$@" = The arguments that were passed to the command.
#
# Example:
#   enforce_constraints --no-project --no-params "$@"
#
function enforce_constraints() {
    while true; do
      case "$1" in

        # validate if a project name must be provided
        --project)
            [[ $ProjectName ]] \
             || fatal_error "The '$CommandName' command requires a project name to be provided" \
                "If the project is 'webui', you can run: ./$ScriptName webui.$CommandName" \
                "To see a list of available projects, use: ./$ScriptName list"
            ;;
        # validate if a project name must NOT be provided
        --no-project)
            [[ -z $ProjectName ]] \
             || fatal_error "The '$CommandName' command cannot be applied to any project" \
                "For more information on how to use the '$CommandName' command, please try: ./$ScriptName $CommandName --help"
            ;;
        # validate if the project should already be installed
        --installed)
            is_project_installed "$ProjectName" \
             || fatal_error "The project '$ProjectName' is not installed" \
                "To check which projects are installed, use: ./$ScriptName list" \
                "To install the project '$ProjectName', use: ./$ScriptName $ProjectName.install"
            ;;
        # validate if NO additional parameters must be provided
        --no-params)
            [[ -n "$*" ]] \
             || fatal_error "The parameter $1 is unknown" \
                "For more information on how to use the '$CommandName' command, please try: ./$ScriptName $CommandName --help"
            ;;
        # any other type of option is unknown
        --*)
            bug_report "Unknown option passed to the enforce_constraints() function: $1"
            ;;
        *)
            break
            ;;
      esac
      shift
    done
}

# Function that checks whether a given command is available in the system
# and prints an error message with installation instructions if it is not.
# Usage: ensure_command <command>
# Arguments:
#   - command: the name of the command to be checked.
#
function require_system_command() {
    for cmd in "$@"; do
        if ! command -v $cmd &> /dev/null; then
            echox error "$cmd is not available!"
            echox "   you can try to install '$cmd' using the following command:"
            echox "   > sudo dnf install $cmd\n"
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
function ask_confirmation() {
    local message=$1 alert=$2

    if [[ $alert ]]; then
        echox
        echox alert "$alert"
    fi
    echox
    read -p " - $message (y/n): " -n 1 -r ; echo ; echo
    [[ $REPLY =~ ^[Yy]$ ]]
}
