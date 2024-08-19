#!/usr/bin/env bash
# File    : commands/list.sh
# Brief   : Command to list available projects
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
HELP="
Usage: $SCRIPT_NAME $COMMAND_NAME

  List all available projects.

Options:
  -h, --help     show command help
  -V, --version  show $SCRIPT_NAME version and exit

Examples:
  $SCRIPT_NAME $COMMAND_NAME
"

function run_command() {
    enforce_constraints --no-project --no-params "$@"
    local projects brief mark

    projects=$(project_info all)
    echo
    IFS=' '; for project in $projects; do
        is_project_installed "$project" && mark='>' || mark=' '
        brief=$(project_info "$project" @brief)
        printf "  %s %-8s : %s\n" "$mark" "$project" "$brief"
    done
    echo
}
