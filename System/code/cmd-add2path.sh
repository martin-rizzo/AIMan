#!/usr/bin/env bash
# File    : cmd-add2path.sh
# Brief   : Command to ...
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
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
Usage: $ScriptName add2path

add $ScriptName script to the system's PATH, allowing you to run it from any directory.

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName add2path
"


function run_command() {
    local options=$1
    local file=~/.bashrc
    local line_to_add='export PATH=$PATH'":$MainDir"
    
    if [[ $options ]]; then
        echoex error "unrecognized options: $options"
        exit 1
    fi
        
    # check if the ~/.bashrc file exists
    if [[ ! -e $file ]]; then
        echoex fatal "unable to set PATH. '$file' file does not exist"
        exit 1    
    fi
    # check if the line to add already exists in the ~/.bashrc file
    if grep -Fxq "$line_to_add" $file; then
        echoex check 'the script is already in the path'
    else
        echoex wait "modifying the '$file' file"
        echo "$line_to_add" >> $file
        echoex info "to activate the changes, run 'source ~/.bashrc' or restart your shell"
    fi
}
