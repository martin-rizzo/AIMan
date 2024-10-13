#!/usr/bin/env bash
# File    : commands/remove.sh
# Brief   : Command to remove projects from the aiman directory
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 14, 2024
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
#shellcheck disable=SC2034
HELP="
Usage: $SCRIPT_NAME PROJECT.$COMMAND_NAME

  Remove a project from the aiman directory.

Options:
  -h, --help     show command help
  -V, --version  show $SCRIPT_NAME version and exit

Examples:
  $SCRIPT_NAME comfyui.$COMMAND_NAME
"

function run_command() {
    enforce_constraints --project - "$@"

    # select the project to extract information from,
    # it will be referenced with '@' from now on
    project_info "$PROJECT_NAME"

    # get project information
    local project_dir port venv python repo hash handler
    project_dir=$(project_info @ @local_dir )
    venv=$(project_info        @ @local_venv)
    repo=$(project_info        @ @repo      )
    hash=$(project_info        @ @hash      )
    handler=$(project_info     @ @handler   )
    port=$PROJECT_PORT
    python=$COMPATIBLE_PYTHON

    # ensure the project is installed before attempting to remove it
    if ! is_project_installed "$PROJECT_NAME"; then
        fatal_error "The project '$PROJECT_NAME' is not installed" \
            "To check which projects are installed, use: ./$SCRIPT_NAME list" \
            "To install the project '$PROJECT_NAME', use: ./$SCRIPT_NAME $PROJECT_NAME.install"
    fi

    # verify that the internal state is correct
    [[ -n "$REPOS_DIR" && -n "$VENV_DIR" ]] \
      || bug_report "Something is not right, \$REPOS_DIR or \$VENV_DIR appear to be empty"

    # ensure the directories are valid
    [[ "$project_dir" == "$REPOS_DIR/"* ]] \
      || bug_report "\$project_dir seems to contain an invalid path: $project_dir"
    [[ "$venv" == "$VENV_DIR/"* ]] \
      || bug_report "\$venv seems to contain an invalid path: $venv"

    # ask for user confirmation before removing the project
    if ! ask_confirmation \
          "Are you sure you want to remove the project '$PROJECT_NAME'?" \
          "While AIMan always tries to keep the models and data isolated and protected from each installation, it's possible that application-specific extensions or configurations may be removed."
    then
        # if the user cancelled, do nothing
        echox "Project removal cancelled."
        exit 0
    fi

    # ensure the project script file exists
    [[ -f $handler ]] \
    || bug_report "AIMan does not have a handler for the '$PROJECT_NAME' project"
    #shellcheck source=/dev/null
    source "$handler"

    # remove any extra files that were installed outside the main project
    if is_valid_function _init_ cmd_remove_extra; then
        _init_ "$PROJECT_NAME" "$port" "$venv" "$python" "$project_dir" "$repo" "$hash"
        cmd_remove_extra
    fi

    # proceed to remove the project
    echox wait "Removing project '$PROJECT_NAME'"
    rm -rf "$project_dir" "$venv"
    echox check "Project '$PROJECT_NAME' has been removed."
}
