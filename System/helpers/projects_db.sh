#!/usr/bin/env bash
# File    : helpers/projects_db.sh
# Brief   : Functions for reading the database of available projects
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 10, 2024
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
declare -a CUR_PROJECT_INFO
PROJECTS_DB=

# load_project - loads info about a project from a file called "projects.csv"
#
# Arguments:
#   $1 - the name of the project to look up
#
# Globals:
#   CUR_PROJECT_INFO - an array that stores info for the current loaded project
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
    [[ ${#CUR_PROJECT_INFO[@]} -ne 0 ]] && \
        fatal_error "The project was loaded twice using 'load_project()', which is not fully supported."

    IFS=','; while read -r project dir repo hash license name brief description; do
        if [[ $project == $project_to_find ]]; then
            CUR_PROJECT_INFO[0]=$project
            CUR_PROJECT_INFO[1]=$dir
            CUR_PROJECT_INFO[2]=$repo
            CUR_PROJECT_INFO[3]=$hash
            CUR_PROJECT_INFO[4]=$license
            CUR_PROJECT_INFO[5]=$name
            CUR_PROJECT_INFO[6]=$brief
            CUR_PROJECT_INFO[7]=$description
            if [[ -z $PythonDir ]]; then
                PythonDir="$RepoDir/${CUR_PROJECT_INFO[1]}-venv"
            fi
            return 0
        fi
    done <<< "$PROJECTS_DB"
    CUR_PROJECT_INFO=()
    return 1
}

# print_project - prints info about the current project based on the parameters
#
# Arguments:
#   Any number of parameters may be passed to the function, which
#   correspond to the project information to be printed.
#   Valid parameters are:
#     "@local_dir"   - prints the project's local directory
#     "@local_venv"  - prints the project's virtual python environment dir
#     "@repo"        - prints the project's repository URL
#     "@hash"        - prints the project's commit hash
#     "@license"     - prints the project's license
#     "@name"        - prints the project's name
#     "@brief"       - prints a brief description of the project
#     "@description" - prints a more detailed description of the project
#     Any other parameter will be printed as-is.
#
# Globals:
#   CUR_PROJECT_INFO - an array that stores info for the current loaded project
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
            "@local_dir"  ) echo -n "${CUR_PROJECT_INFO[1]}" ;;
            "@local_venv" ) echo -n "$PythonDir"          ;;
            "@repo"       ) echo -n "${CUR_PROJECT_INFO[2]}" ;;
            "@hash"       ) echo -n "${CUR_PROJECT_INFO[3]}" ;;
            "@license"    ) echo -n "${CUR_PROJECT_INFO[4]}" ;;
            "@name"       ) echo -n "${CUR_PROJECT_INFO[5]}" ;;
            "@brief"      ) echo -n "${CUR_PROJECT_INFO[6]}" ;;
            "@description") echo -n "${CUR_PROJECT_INFO[7]}" ;;
            *)              echo -n "$parameter"          ;;
        esac
    done
    echo
}

function is_valid_project() {
    local project=$1
    grep -q "^$project," <<< "$PROJECTS_DB"
}

function set_projects_db() {
    local csv_db_file=$1

    # recorrer cada una de las lineas del CSV para purificar un poco su
    # contenido eliminando espacios inesesarios.
    IFS=','; while read -r project dir repo hash license name brief description; do
        project=$(trim "$project")
        dir=$(trim "$dir")
        repo=$(trim "$repo")
        hash=$(trim "$hash")
        license=$(trim "$license")
        name=$(trim "$name")
        brief=$(trim "$brief")
        description=$(trim "$description")
        PROJECTS_DB+="$project,$dir,$repo,$hash,$license,$name,$brief,$description
"
    done < "$csv_db_file"
}
