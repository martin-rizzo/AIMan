#!/usr/bin/env bash
# File    : helpers.sh
# Brief   : Contains helper functions, e.g: printing status, checking cmds..
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
# Repo    : https://github.com/martin-rizzo/AIAppManager
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                    AIMan
#        A basic package management system for AI open source projects
#   
#     Copyright (c) 2023 Martin Rizzo
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
function echoex() {
    local format=$1 prefix='' suffix=''

    case "$format" in
        check) prefix='\033[32m \xE2\x9C\x94 ' ; suffix='\033[0m' ; shift ;;
        wait ) prefix='\033[33m - ' ; suffix='...\033[0m' ; shift ;;
        info ) prefix='\033[96m \xE2\x93\x98 ' ; suffix='\033[0m' ; shift ;;
        warn ) prefix='\033[93m ! ' ; suffix='\033[0m' ; shift ;;
        error) prefix='\033[31m \xE2\x9C\x96 ' ; suffix='\033[0m' ; shift ;;
        fatal) prefix='\033[7;31m \xE2\x9C\x96\xE2\x9C\x96 ' ; suffix='\033[0m' ; shift ;;
    esac
    echo -e -n "$prefix"
    echo    -n $@
    echo -e    "$suffix"
}

# Function to display an error message for unrecognized arguments
# $@ - all the arguments that were not recognized
error_unrecognized_arguments() {
  echo "Error: Unrecognized argument(s): $@"
  exit 1
}


#---------------------------------- GIT ------------------------------------#

function clone_project_to() {
    local directory=$1 repo=$2 hash=$3
    local previous_dir=$(pwd)
    
    if [[ -z $directory ]]; then
        echoex fatal 'clone_project_to() requires the "directory" parameter.'
        echoex info  'Usage: clone_project_to <directory> [repo] [hash]'
        exit 1
    fi
    if [[ -z $repo ]]; then
        repo=$(print_project @repo)
    fi
    if [[ -z $hash ]]; then
        hash=$(print_project @hash)
    fi
    git clone "$repo" "$directory"
    if [[ $hash != '-' && ${#hash} -ge 6 ]]; then
        cd "$directory"
        git reset --hard "$hash"
    fi
    cd "$previous_dir" &> /dev/null
}


#-------------------------------- SYSTEM ----------------------------------#


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

# Function that checks whether a given command is available in the system
# and prints an error message with installation instructions if it is not.
# Usage: ensure_command <command>
# Arguments:
#   - command: the name of the command to be checked.
#
#------------------------ PYTHON VIRT ENVIRONMENT --------------------------#


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



#------------------------------ PROJECT INFO -------------------------------#

declare -a cur_proj_info

# load_project - loads info about a project from a file called "projects.lst"
#
# Arguments:
#   $1 - the name of the project to look up
#
# Globals:
#   cur_proj_info - an array that stores info for the current loaded project
#
# Returns:
#   None
#
# Example:
#   load_project "webui"
#
function load_project() {
    local project_to_find=$1
    local IFS=,
    while read -r project dir repo hash license name brief description; do
        cur_proj_info[0]=${project##* }
        cur_proj_info[1]=${dir##* }
        cur_proj_info[2]=${repo##* }
        cur_proj_info[3]=${hash##* }
        cur_proj_info[4]=${license##* }
        cur_proj_info[5]=${name##* }
        cur_proj_info[6]=${brief##* }
        cur_proj_info[7]=${description##* }
        if [[ $project == $project_to_find ]]; then
            return
        fi
    done < "$CodeDir/projects.lst"
    cur_proj_info=()
}

# print_project - prints info about the current project based on the parameters
#
# Arguments:
#   Any number of parameters may be passed to the function, which
#   correspond to the project information to be printed.
#   Valid parameters are:
#     "@directory"   - prints the project's directory
#     "@repo"        - prints the project's repository URL
#     "@hash"        - prints the project's commit hash
#     "@license"     - prints the project's license
#     "@name"        - prints the project's name
#     "@brief"       - prints a brief description of the project
#     "@description" - prints a more detailed description of the project
#     Any other parameter will be printed as-is.
#
# Globals:
#   cur_proj_info - an array that stores info for the current loaded project
#
# Returns:
#   None
#
# Example:
#   print_project @name @description @repo
#   Output: "Project Description of the project https://github.com/user/project.git"
#
function print_project() {
    # loop through each parameter passed to the function
    for parameter in "$@"; do
        case $parameter in
            "@directory"  ) echo -n "${cur_proj_info[1]}" ;;
            "@repo"       ) echo -n "${cur_proj_info[2]}" ;;
            "@hash"       ) echo -n "${cur_proj_info[3]}" ;;
            "@license"    ) echo -n "${cur_proj_info[4]}" ;;
            "@name"       ) echo -n "${cur_proj_info[5]}" ;;
            "@brief"      ) echo -n "${cur_proj_info[6]}" ;;
            "@description") echo -n "${cur_proj_info[7]}" ;;
            *)              echo -n "$parameter"          ;;
        esac
    done
    echo
}


