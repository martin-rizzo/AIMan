#!/usr/bin/env bash
# File    : cmd-launch.sh
# Brief   : Command to ...
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 11, 2023
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
Usage: $ScriptName launch PROJECT

launch ...

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName launch webui
"



function run_command() {
    local options=$1 project=$2
    
    if [[ ! -e "$CodeDir/project-$project.sh" ]]; then
        echo error "unknown project $project"
        exit 1
    fi
    source "$CodeDir/project-$project.sh"
    load_project $project
    launch
}
