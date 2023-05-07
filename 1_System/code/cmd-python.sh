#!/usr/bin/env bash
# File    : cmd-python.sh
# Brief   : Command to manage the python virtual environment
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
Usage: $ScriptName python <action>

manage the python virtual environment

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName python activate
    $ScriptName python destroy
"


function run_command() {
    local options=$1 subcommand=$2
    local exitmsg="To exit from this Python virtual environment, type 'exit' and press Enter."

    case $subcommand in
        activate)
            require_virtual_python
            if is_virtual_python; then
                #echoex check "virtual environment already activated (nothing to do)"
                echoex check "virtual environment is already activated (no further action is necessary)"
                echoex "$exitmsg"
            else
                echoex wait "activating virtual environment"
                echoex "$exitmsg"
                /usr/bin/env bash -i -c \
                    "source '$PythonDir/bin/activate'; exec /bin/bash -i"
            fi
            ;;
        destroy)
            rm -Rf "$PythonDir"
            ;;
        *)
            echo "invalid command"
            ;;
    esac
}

