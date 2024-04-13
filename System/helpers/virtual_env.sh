#!/usr/bin/env bash
# File    : helpers/virtual_env.sh
# Brief   : Functions para el manejo de entornos virtuales de python
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 11, 2024
# Repo    : https://github.com/martin-rizzo/AIAppManager
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
#
# FUNCTIONS:
#  - require_virtual_python() :
#  - is_virtual_python()      :
#  - virtual_python()         :
#  - activate_python_env()    :
#
#-----------------------------------------------------------------------------

function require_virtual_python() {

    if [[ ! -d $PythonDir ]]; then
        echox wait 'creating python virtual environment'
        "$CompatiblePython" -m venv "$PythonDir" --prompt "$PythonPrompt"
        echox check 'new python virtual environment created:'
        echox  "     $PythonDir"
    elif [[ ! -e "$PythonDir/bin/$CompatiblePython" ]]; then
        echox warn "a different version of python was selected ($CompatiblePython)"
        echox wait "recreating virtual environment"
        rm -Rf "$PythonDir"
        "$CompatiblePython" -m venv "$PythonDir" --prompt "$PythonPrompt"
        echox check "virtual environment recreated for $CompatiblePython"
    else
        echox check 'virtual environment exists'
    fi
}

# Function that checks whether a virtual environment exists, and creates
# a new one if it doesn't.
# Usage: ensure_virt_env <venv_dir> <python>
# Arguments:
#   - venv_dir: the path of the virtual environment dir to be checked.
#   - python  : the Python interpreter that will create the v. environment.
#
function is_virtual_python() {
    local current_virtual_dir=$VIRTUAL_ENV
    if [[ -z $current_virtual_dir ]]; then
        return 1
    fi
    if [[ $current_virtual_dir == '~'* ]]; then
        current_virtual_dir="${current_virtual_dir/\~\//}"
    fi
    if [[ "$PythonDir" == *"$current_virtual_dir" ]]; then
        return 0
    else
        return 1
    fi
}


# virtual_python <venv_dir> <python_script.py> [params...]
# virtual_python <venv_dir> !<command> [params...]
# virtual_python <venv_dir> 'CONSOLE'

function virtual_python() {

    # 1) ensure virtual environment is activated
    if ! is_virtual_python; then
        echox wait 'activating virtual environment'
        source "$PythonDir/bin/activate"
        echox check 'virtual environment activated'
    else
        echox check "virtual environment already activated"
    fi

    # 2) execute command inside the virtual environment
    if [[ "$1" == "!"* ]]; then
        # remove the '!' character from the beginning of the first param
        # and execute that command with the rest of the arguments
        local command_name=${1:1}
        shift
        "$command_name" "$@"
    else
        python $@
    fi
}

function activate_python_env() {
    local mode=$1
    local venv_prompt="aiman-$CompatiblePython"
    ensure_python_env

    if [[ $mode == 'subshell' ]]; then
        /usr/bin/env bash -i -c "source '$PythonDir/bin/activate'; exec /bin/bash -i"
        exit 0
    else
        source "$PythonDir/bin/activate"
    fi
}


