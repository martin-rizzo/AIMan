#!/usr/bin/env bash
# File    : commands/info.sh
# Brief   : Command to display details about each project
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
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
Usage: $ScriptName [PROJECT.]info

  display details about a project

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName webui.info
"

function run_command() {
    local first_param=$1

    # this command does not support any parameters
    if [[ -n $first_param ]]; then
        error_unrecognized_arguments $param
    fi

    # ensure the user has provided a project name
    # if not, display the help information and exit without taking any action
    if [[ -z $ProjectName ]]; then
        echo "$Help"
        exit 0
    fi

    # load the project specified by the user and display all relevant info
    load_project "$ProjectName"
    echo
    print_project "Name        :" @name
    print_project "Summary     :" @brief
    print_project "License     :" @license
    print_project "Directory   :" @local_dir
    print_project "Virt.enviro :" @local_venv
    print_project "Repository  :" @repo
    print_project "Hash        :" @hash
    print_project "Description :" @description
    echo
}
