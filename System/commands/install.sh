#!/usr/bin/env bash
# File    : cmd-install.sh
# Brief   : Command to install projects on the aiman directory
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 6, 2023
# Repo    : https://github.com/martin-rizzo/AIMan
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
Help="
Usage: $ScriptName PROJECT.install [version]

  install a project on the aiman directory

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName webui.install v1.8.0
"

function run_command() {
    enforce_constraints --project "$@"
    local version=$1

    # retrieve project information
    project_info "$ProjectName"
    local project_id=$(project_info @ @id)
    local project_dir=$(project_info @ @local_dir)
    local venv=$(project_info @ @local_venv)
    local repo=$(project_info @ @repo)
    local hash=$(project_info @ @hash)
    local script=$(project_info @ @script)

    # ensure the project script file exists
    if [[ ! -f $script ]]; then
        fatal_error "AIMan does not have a script for the '$project_id' project" \
            "This is an internal error likely caused by a mistake in the code"
    fi

    # if the user provided a version, use it to override the hash
    if [[ $version ]]; then
        hash=$version
    fi

    source "$script"
    install "$venv" "$project_dir" "$repo" "$hash"
}
