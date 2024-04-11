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

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
DEFAULT_COLOR='\e[0m'
PADDING='   '


# Prints messages with different formats. If the format is not specified,
# the message will be printed like the echo command.
#
# Usage: echoex [format] message
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
        wait ) prefix="\033[33m - " ; suffix="...${DEFAULT_COLOR}" ; shift ;;
        info ) prefix="${CYAN}\xE2\x93\x98  " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        warn ) prefix="${PADDING}${YELLOW}! " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        error) prefix="${CYAN}[${RED}ERROR${CYAN}]${DEFAULT_COLOR}: " ; suffix="${DEFAULT_COLOR}" ; shift ;;
        #fatal) prefix='\033[7;31m \xE2\x9C\x96\xE2\x9C\x96 ' ; suffix='\033[0m' ; shift ;;
    esac
    echo -e -n "$prefix"
    echo    -n "$@"
    echo -e    "$suffix"
}

function trim() {
    local input=$1
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"
    echo "$input"
}

# Compatibility with legacy code
# TODO: Remove all uses of 'echoex' from the entire codebase and replace
#       them with 'echox'.
#
function echoex() {
    echox "$@"
}

function fatal_error() {
    local fatal_message=$1 comment=$2
    echo
    [[ -n $fatal_message ]] && echox error "$fatal_message"
    [[ -n $comment       ]] && echox info  "$comment"
    echo
    exit 1
}

# Function to display an error message for unrecognized arguments
# $@ - all the arguments that were not recognized
error_unrecognized_arguments() {
  echo "Error: Unrecognized argument(s): $@"
  exit 1
}


#---------------------------------- GIT ------------------------------------#

function clone_project_to() {
    local directory=$1 hash_or_tag=$2 repo=$3
    local previous_dir=$(pwd)

    if [[ -z $directory ]]; then
        fatal_error 'clone_project_to() requires the "directory" parameter.' \
                    'Usage: clone_project_to <directory> [repo] [hash]'
    fi
    if [[ -z $repo ]]; then
        repo=$(print_project @repo)
    fi
    if [[ -z $hash_or_tag ]]; then
        hash_or_tag=$(print_project @hash)
    fi
    git clone "$repo" "$directory"
    if [[ $hash_or_tag != '-' ]]; then
        cd "$directory"
        git reset --hard "$hash_or_tag"
    fi
    cd "$previous_dir" &> /dev/null
}


#--------------------------------- SYSTEM ----------------------------------#

# Function that checks whether a given command is available in the system
# and prints an error message with installation instructions if it is not.
# Usage: ensure_command <command>
# Arguments:
#   - command: the name of the command to be checked.
#
function require_system_command() {
    for cmd in "$@"; do
        if ! command -v $cmd &> /dev/null; then
            echoex error "$cmd is not available!"
            echoex "   you can try to install '$cmd' using the following command:"
            echoex "   > sudo dnf install $cmd\n"
            exit 1
        else
            echoex check "$cmd is installed"
        fi
    done
}


#----------------------- PYTHON VIRTUAL ENVIRONMENT ------------------------#


function require_virtual_python() {

    if [[ ! -d $PythonDir ]]; then
        echoex wait 'creating python virtual environment'
        "$CompatiblePython" -m venv "$PythonDir" --prompt "$PythonPrompt"
        echoex check 'new python virtual environment created:'
        echoex  "     $PythonDir"
    elif [[ ! -e "$PythonDir/bin/$CompatiblePython" ]]; then
        echoex warn "a different version of python was selected ($CompatiblePython)"
        echoex wait "recreating virtual environment"
        rm -Rf "$PythonDir"
        "$CompatiblePython" -m venv "$PythonDir" --prompt "$PythonPrompt"
        echoex check "virtual environment recreated for $CompatiblePython"
    else
        echoex check 'virtual environment exists'
    fi
}

# Function that checks whether a virtual environment exists, and creates
# a new one if it doesn't.
# Usage: ensure_virt_env <venv_dir> <python>
# Arguments:
#   - venv_dir: the path of the virtual environment dir to be checked.
#   - python  : the Python interpreter that will create the v. environment.
#
function is_virtual_python() {
    local current_virtual_dir=$VIRTUAL_ENV
    if [[ -z $current_virtual_dir ]]; then
        return 1
    fi
    if [[ $current_virtual_dir == '~'* ]]; then
        current_virtual_dir="${current_virtual_dir/\~\//}"
    fi
    if [[ "$PythonDir" == *"$current_virtual_dir" ]]; then
        return 0
    else
        return 1
    fi
}

function virtual_python() {

    # 1) ensure virtual environment is activated
    if ! is_virtual_python; then
        echoex wait 'activating virtual environment'
        source "$PythonDir/bin/activate"
        echoex check 'virtual environment activated'
    else
        echoex check "virtual environment already activated"
    fi

    # 2) execute command inside the virtual environment
    if [[ "$1" == "!"* ]]; then
        # remove the '!' character from the beginning of the first param
        # and execute that command with the rest of the arguments
        local command_name=${1:1}
        shift
        "$command_name" "$@"
    else
        python $@
    fi
}

function activate_python_env() {
    local mode=$1
    local venv_prompt="aiman-$CompatiblePython"
    ensure_python_env

    if [[ $mode == 'subshell' ]]; then
        /usr/bin/env bash -i -c "source '$PythonDir/bin/activate'; exec /bin/bash -i"
        exit 0
    else
        source "$PythonDir/bin/activate"
    fi
}


