#!/usr/bin/env bash
#shellcheck disable=SC2154 source=/dev/null
# File    : commands/install.sh
# Brief   : Command to install projects on the aiman directory
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 6, 2023
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
HELP="
Usage: $SCRIPT_NAME PROJECT.$COMMAND_NAME [VERSION]

  Install a project on the local directory.

Arguments:
  PROJECT  The name of the project to install
  VERSION  The version of the project to install (optional)

Options:
  -h, --help     show command help
  -V, --version  show $SCRIPT_NAME version and exit

Description:
  The '$COMMAND_NAME' command downloads the specified project from GitHub and
  sets it up on your local system. If no version is provided, the version
  that has been tested as the most stable release will be installed.

  Once the installation is complete, you can use the 'launch' command to
  start the project.

Examples:
    $SCRIPT_NAME forge.$COMMAND_NAME
    $SCRIPT_NAME webui.$COMMAND_NAME v1.8.0
"

function run_command() {
    enforce_constraints --project "$@"
    local version=$1

    # select the project to extract information from,
    # it will be referenced with '@' from now on
    project_info "$PROJECT_NAME"

    # if the project is already installed,
    # terminate with an error and display information to the user
    if is_project_installed @; then
      fatal_error "Project '$PROJECT_NAME' is already installed." \
        "If $PROJECT_NAME is incorrectly installed, you can try uninstalling it with '$SCRIPT_NAME $PROJECT_NAME.remove' and installing it again."
    fi

    # extract project information.
    local project_dir venv repo hash handler
    project_dir=$(project_info @ @local_dir)
    venv=$(project_info @ @local_venv)
    repo=$(project_info @ @repo)
    hash=$(project_info @ @hash)
    handler=$(project_info @ @script)

    # ensure the project script file exists
    [[ -f $handler ]] \
     || bug_report "AIMan does not have a handler for the '$PROJECT_NAME' project"

    # if the user provided a version, use it to override the hash
    if [[ $version ]]; then
        hash=$version
    fi

    # execute the install command from the project handler
    source "$handler"
    install "$venv" "$project_dir" "$repo" "$hash"
}
