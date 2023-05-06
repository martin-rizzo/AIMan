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

#---------------------------------- GIT ------------------------------------#

function clone_project() {
    local directory=$1 repo=$2 hash=$3
    
    if [[ -z $repo ]]; then
        repo=$(print_project @repo)
    fi
    if [[ -z $directory ]]; then
        directory=$(print_project @directory)
    fi
    if [[ -z $hash ]]; then
        hash=$(print_project @hash)
    fi
    git clone "$repo" "$directory"
    cd "$directory"
    git reset --hard "$hash"
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


