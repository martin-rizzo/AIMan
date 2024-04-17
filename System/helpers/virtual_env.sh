#!/usr/bin/env bash
# File    : helpers/virtual_env.sh
# Brief   : Utilities for managing Python virtual environments
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
#  - is_venv_active()             : Checks if the virtual environment is active.
#  - ensure_venv_is_initialized() : Ensures that a virtual environment is created and initialized.
#  - ensure_venv_is_active()      : Ensures that a virtual environment is active.
#  - virtual_python()             : Runs a command or Python script within the specified virtual environment.
#
#-----------------------------------------------------------------------------


# Checks if the Python virtual environment is active.
#
# Usage:
#   is_venv_active <venv>
#
# Parameters:
#   - venv: the path to the virtual environment to check.
#
# Returns:
#   - 0 if the specified virtual environment is active
#   - 1 if no virtual environment is active
#   - 2 if a different virtual environment is active
#
# Example:
#   is_venv_active "/path/to/my-venv"
#
function is_venv_active() {
    local venv=$1
    if [[ -z $VIRTUAL_ENV ]]; then
        return 1 # NO ACTIVE #
    fi
    if [[ "$venv" != *"${VIRTUAL_ENV#\~}" ]]; then
        return 2 # NO ACTIVE (otro venv esta activo) #
    fi
    return 0 # ACTIVE! #
}

# Ensures that the Python virtual environment is created and initialized.
#
# Usage:
#   ensure_venv_is_initialized <venv>
#
# Parameters:
#   - venv: the path to the virtual environment to be initialized.
#
# Example:
#   ensure_venv_is_initialized "/path/to/my-venv"
#
function ensure_venv_is_initialized() {
    local venv=$1
    local venv_prompt="venv"

    # verify that the 'venv' parameter is a subdirectory of $VEnvDir
    if [[ "$venv" != "$VEnvDir"* ]]; then
        fatal_error \
            "'ensure_venv_is_initialized()' failed, the provided venv '$venv' is not a subdir of \$VEnvDir."
            "This is an internal error likely caused by a mistake in the code."
    fi

    local venv_prompt=$(basename "$venv")
    venv_prompt="${venv_prompt%-venv} venv"

    # if the venv does not exist, then create it
    if [[ ! -d $venv ]]; then
        echox wait 'creating python virtual environment'
        echox "      > '$CompatiblePython' -m venv '$venv' --prompt '$venv_prompt'"
        "$CompatiblePython" -m venv "$venv" --prompt "$venv_prompt"
        echox check 'new python virtual environment created:'
        echox  "     $venv"

    # if the venv already exists but contains a different version of Python,
    # then try to delete it and recreate it with the compatible version
    elif [[ ! -e "$venv/bin/$CompatiblePython" ]]; then
        echox warn "a different version of python was selected ($CompatiblePython)"
        echox wait "recreating virtual environment"
        rm -Rf "$venv"
        "$CompatiblePython" -m venv "$venv" --prompt "$venv_prompt"
        echox check "virtual environment recreated for $CompatiblePython"

    # if the venv exists and has the correct version of Python, do nothing!
    else
        echox check 'virtual environment exists'
    fi
}

# Ensures the specified Python virtual environment is active.
#
# Usage:
#   ensure_venv_is_active <venv>
#
# Parameters:
#   - venv: the path to the Python virtual environment to be activated.
#
# Example:
#   ensure_venv_is_active "/path/to/my-venv"
#
function ensure_venv_is_active() {
    local venv=$1

    if is_venv_active "$venv"; then
        echox check "virtual environment already activated"
        return
    fi

    if [[ $? -eq 2 ]]; then
        fatal_error \
            "function ensure_venv_is_active() is unable to switch between virtual environments" \
            "This is an internal error likely caused by a mistake in the code"
    fi

    echox wait 'activating virtual environment'
    source "$venv/bin/activate"
    echox check 'virtual environment activated'
}

# Runs a command or Python script within the specified virtual environment.
#
# Usage:
#   virtual_python <venv> <command> [args...]
#
# Parameters:
#   - venv: the path to the Python virtual environment to use.
#   - command:
#      - CONSOLE: Opens an interactive shell in the virtual environment.
#      - filename starting with "!": Runs the specified Python script.
#      - otherwise: runs the specified command with any additional arguments.
#   - args...: additional arguments to pass to the command or Python script.
#
# Returns:
#   The exit status of the executed command or Python script.
#
# Examples:
#   virtual_python "/path/to/my-venv" CONSOLE
#   virtual_python "/path/to/my-venv" !my_script.py arg1 arg2
#   virtual_python "/path/to/my-venv" pip install numpy
#
function virtual_python() {
    local venv=$1 command=$2
    shift 2

    ensure_venv_is_initialized "$venv"

    if [[ $command == 'CONSOLE' ]]; then
        source "$venv/bin/activate"
        exec /bin/bash --norc -i
        exit 0
    fi

    ensure_venv_is_active "$venv"

    # si el comando empieza con '!' entonces es script python
    # de lo contrario es un comando normal de linux
    if [[ "$command" == "!"* ]]; then
        python "${command:1}" "$@"
    else
        "$command" "$@"
    fi
}

