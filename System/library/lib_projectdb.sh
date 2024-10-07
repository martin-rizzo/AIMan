#!/usr/bin/env bash
#shellcheck disable=SC2154
# File    : library/lib_projectdb.sh
# Brief   : Functions for loading and querying the database of available projects
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 10, 2024
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
#   - load_project_db()      : Loads the project database
#   - project_info()         : Displays information about a project
#   - is_valid_project()     : Checks if a project is valid
#   - is_project_installed() : Checks if a project is installed locally
#
#-----------------------------------------------------------------------------

# Holds the loaded database populated by the 'load_projects_db' function.
PROJECTS_DB=
PROJECTS_LIST=

# Array that holds the information about the last queried project. This allows
# the 'print_project' function to quickly retrieve the project details without
# having to search the database again.
declare -a CACHE_PROJECT_INFO


# Loads the project database
#
# Usage:
#   load_projects_db <csv_db_file>
#
# Parameters:
#   - csv_db_file: the path to the CSV file containing the project database
#
# This function is called only once at the beginning of the program to
# load the project database from the CSV file. The format of each line
# in the CSV file is:
#     project,dir,repo,hash,license,name,brief,description
#
load_project_db() {
    local csv_db_file=$1
    # iterate through each line of the CSV file
    IFS=','; while read -r project_handler dir repo hash license name brief description; do
        # skip lines starting with '#'
        [[ -z "$project_handler" || $project_handler == \#* ]] && continue

        local project handler

        # if a colon is present in the project name,
        # separate the project and handler
        if [[ $project_handler =~ ':' ]]; then
            project=${project_handler%%:*}  # <- extract everything before the first ':'
            handler=${project_handler##*:}  # <- extract everything after the last ':'
        # if no colon is present, project and handler are the same
        else
            project=$project_handler
            handler=$project_handler
        fi

        # trim all strings to prevent potential errors.
        # (unexpected spaces could lead to incorrect comparisons or file path issues)
        project=$(trim "$project")
        handler=$(trim "$handler")
        dir=$(trim "$dir")
        repo=$(trim "$repo")
        hash=$(trim "$hash")
        license=$(trim "$license")
        name=$(trim "$name")
        brief=$(trim "$brief")
        description=$(trim "$description")

        # append the trimmed project information to the $PROJECTS_DB variable
        PROJECTS_LIST+="$project "
        PROJECTS_DB+="$project,$handler,$dir,$repo,$hash,$license,$name,$brief,$description
"
    done < "$csv_db_file"
}

# Displays information about a project from the project database
#
# Usage:
#   project_info <project_name> [param1] [param2] ... [paramN]
#
# Parameters:
#   - project_name: the name of the project to retrieve information for.
#
#   Any number of parameters may be passed to the function, which
#   correspond to the project information to be printed.
#   Valid parameters are:
#      "@local_dir"   : Outputs the local directory of the project.
#      "@local_venv"  : Outputs the local virtual environment directory of the project.
#      "@handler"     : Outputs the path of the AIMan script responsible for managing the project.
#      "@repo"        : Outputs the repository URL of the project.
#      "@hash"        : Outputs the commit hash of the project.
#      "@license"     : Outputs the license of the project.
#      "@name"        : Outputs the full name of the project.
#      "@brief"       : Outputs a brief description of the project.
#      "@description" : Outputs the full description of the project.
#      Any other parameter will be printed as-is.
#
# Example:
#   project_info my_project @local_dir @name @brief
#   project_info all
#
project_info() {
    local project_name=$1

    # en el caso aparte de que el nombre del proyecto sea "all"
    # se hace output de los IDs de TODOS los proyectos (separados por espacio)
    if [[ $project_name == "all" ]]; then
        echo -n "$PROJECTS_LIST"
        return
    fi

    # if the project name is not cached, then search for it in '$PROJECT_DB'
    # (if '@' is provided as the project name, it means that the cache content should be printed)
    if [[ $project_name != '@' && $project_name != "${CACHE_PROJECT_INFO[0]}" ]]; then
        CACHE_PROJECT_INFO=()
        IFS=','; while read -r project handler local_dir repo hash license name brief description; do
            if [[ $project == "$project_name" ]]; then
                CACHE_PROJECT_INFO[0]=$project
                CACHE_PROJECT_INFO[1]="$REPOS_DIR/${local_dir}"
                CACHE_PROJECT_INFO[2]="$VENV_DIR/$project-venv"
                CACHE_PROJECT_INFO[3]="$HANDLERS_DIR/$handler.sh"
                CACHE_PROJECT_INFO[4]=$repo
                CACHE_PROJECT_INFO[5]=$hash
                CACHE_PROJECT_INFO[6]=$license
                CACHE_PROJECT_INFO[7]=$name
                CACHE_PROJECT_INFO[8]=$brief
                CACHE_PROJECT_INFO[9]=$description
                break
            fi
        done <<< "$PROJECTS_DB"
    fi

    # if there are more parameters after the project_name,
    # then loop through each of them and print what they indicate
    if [[ $# -gt 1 ]]; then
        shift
        for parameter in "$@"; do
            case "$parameter" in
                "@id"         ) echo -n "${CACHE_PROJECT_INFO[0]}" ;;
                "@local_dir"  ) echo -n "${CACHE_PROJECT_INFO[1]}" ;;
                "@local_venv" ) echo -n "${CACHE_PROJECT_INFO[2]}" ;;
                "@handler"    ) echo -n "${CACHE_PROJECT_INFO[3]}" ;;
                "@repo"       ) echo -n "${CACHE_PROJECT_INFO[4]}" ;;
                "@hash"       ) echo -n "${CACHE_PROJECT_INFO[5]}" ;;
                "@license"    ) echo -n "${CACHE_PROJECT_INFO[6]}" ;;
                "@name"       ) echo -n "${CACHE_PROJECT_INFO[7]}" ;;
                "@brief"      ) echo -n "${CACHE_PROJECT_INFO[8]}" ;;
                "@description") echo -n "${CACHE_PROJECT_INFO[9]}" ;;
                *)              echo -n "$parameter"          ;;
            esac
        done
        echo
    fi
}

# Checks if a project is valid in the project database
#
# Usage:
#   is_valid_project <project>
#
# Parameters:
#   - project: the name of the project to check
#
# This function checks if the given project is present in the
# '$PROJECTS_DB' variable, which contains the project database
# loaded by the 'load_projects_db' function.
#
is_valid_project() {
    local project=$1
    grep -q "^$project," <<< "$PROJECTS_DB"
}

# Checks if a project is installed locally
#
# Usage:
#   is_project_installed <project>
#
# Parameters:
#   - project: the name of the project to check
#
# This function checks if the given project is installed by
# verifying that its local directory exists.
#
is_project_installed() {
    local project=$1
    local project_dir
    project_dir=$(project_info "$project" @local_dir)
    [[ -n "$project_dir" &&  -d "$project_dir" ]]
}

