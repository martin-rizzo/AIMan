#!/usr/bin/env bash
# File    : commands/launch.sh
# Brief   : Command to launch projects that have been previously installed
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 11, 2023
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
Usage: $ScriptName PROJECT.$CommandName [PARAMETERS...]

  Launch a project that has been previously installed.

Arguments:
  PROJECT     The name of the project to launch
  PARAMETERS  Extra parameters to pass to the project (optional)

Options:
  -h, --help     show command help
  -V, --version  show $ScriptName version and exit

Description:
  The '$CommandName' command starts the specified project on your local system.
  Any extra parameters you provide will be passed directly to the project's
  launch script or executable.

  If the project requires any additional setup or configuration, you should
  refer to the project's documentation for instructions on how to do that
  before launching the project.

  The project will run in the current terminal session until you stop it.
  You can access it through the appropriate URL or interface, as described
  in the project's documentation.

Examples:
  $ScriptName forge.$CommandName
  $ScriptName webui.$CommandName
"

function run_command() {
    enforce_constraints --project --installed "$@"

    # retrieve project information
    project_info "$ProjectName"
    local project_dir=$(project_info @ @local_dir)
    local venv=$(project_info @ @local_venv)
    local repo=$(project_info @ @repo)
    local hash=$(project_info @ @hash)
    local script=$(project_info @ @script)

    # ensure the project script file exists
    [[ -f $script ]] \
     || bug_report "AIMan does not have a script for the '$ProjectName' project"

    source "$script"
    launch "$venv" "$project_dir" "$repo" "$hash" "$@"
}
