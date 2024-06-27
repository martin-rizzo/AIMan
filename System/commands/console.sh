#!/usr/bin/env bash
# File    : commands/console.sh
# Brief   : Execute commands within the Python virtual environment
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
Help="
Usage: $ScriptName PROJECT.$CommandName [COMMAND] [PARAMETERS...]

  Execute commands within the Python virtual environment of the specified project.
  If no command is provided, it will open an interactive console to enter commands.

Arguments:
  COMMAND      The command to execute within the project's virtual environment
  [PARAMETERS  Any parameters to pass to the specified command

Options:
  -h, --help        show this help
  -V, --version     show $ScriptName version and exit

Examples:
  $ScriptName webui.$CommandName
      Open an interactive console for the 'webui' project

  $ScriptName webui.$CommandName pip upgrade
      Run the 'pip upgrade' command within the 'webui' project's virtual environment
"

function run_command() {
    enforce_constraints --project --installed "$@"
    local command=$1
    shift

    # get project information
    project_info "$ProjectName"
    local project_dir=$(project_info @ @local_dir)
    local venv=$(project_info @ @local_venv)

    # ensure the virtual environment directory is valid
    [[ -n "$venv" && "$venv" == "$VEnvDir/"* ]] \
      || bug_report "\$venv seems to contain an invalid path: '$venv'"


    # execute the command provided by the user
    # (if the command is empty, open the interactive console)
    if [[ $command ]]; then
        virtual_python "$venv" "!$command" "$@"
    else
        cd "$project_dir"
        virtual_python "$venv" CONSOLE
    fi
}
