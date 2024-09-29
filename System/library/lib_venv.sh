#!/usr/bin/env bash
# File    : library/lib_venv.sh
# Brief   : Utilities for managing Python virtual environments
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 11, 2024
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
#
# FUNCTIONS:
#  - is_venv_active()      : Checks if a virtual environment is active.
#  - require_venv()        : Ensures a virtual environment exists and is properly configured.
#  - require_active_venv() : Ensures a virtual environment is active.
#  - virtual_python()      : Runs a command or Python script within the a virtual environment.
#
#-----------------------------------------------------------------------------

# Stores the path to the last used virtual environment.
# This variable is used by the `virtual_python()` function.
HLP__LAST_VENV=


# Checks if the virtual environment is active.
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
is_venv_active() {
    local venv=$1
    if [[ -z $VIRTUAL_ENV ]]; then
        return 1 # NO ACTIVE #
    fi
    if [[ "$venv" != *"${VIRTUAL_ENV#\~}" ]]; then
        return 2 # NO ACTIVE (a different venv is active) #
    fi
    return 0 # ACTIVE! #
}


# Ensures a virtual environment exists and is properly configured.
#
# Usage:
#   require_venv [--quiet] <venv> [forced_python] [requirements_file]
#
# Parameters:
#   --quiet           : (optional) suppresses output messages.
#   venv              : path to the virtual environment.
#   forced_python     : (optional) path or command name to a specific python version, overrides default.
#   requirements_file : (optional) path to a requirements.txt file to install packages.
#
# Examples:
#   require_venv "/path/to/my-venv"
#   require_venv --quiet "/path/to/my-venv"
#   require_venv --quiet "/path/to/my-venv" python3.10
#
require_venv() {

    # process initial parameters starting with '-'
    local quiet=false
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            --quiet) quiet=true ;;
            -)       shift; break ;;
            *)       fatal_error "require_venv does not support the option '$1'" ;;
        esac
        shift
    done

    local venv=$1 forced_python=$2 requirements_file=$3

    # construct the virtual environment prompt text
    local venv_prompt
    venv_prompt=$(basename "$venv")
    venv_prompt="${venv_prompt%-venv} venv"

    # determine the Python command; use forced version if provided, otherwise default
    local python_cmd=${forced_python:-${COMPATIBLE_PYTHON:-python}}
    local update=false

    # create the venv if it doesn't exist
    if [[ ! -d $venv ]]; then
        $quiet || message wait 'creating python virtual environment'
        $quiet || message "      > '$python_cmd' -m venv '$venv' --prompt '$venv_prompt'"
        "$python_cmd" -m venv "$venv" --prompt "$venv_prompt"
        update=true
        $quiet || message check 'new python virtual environment created:'
        $quiet || message  "     $venv"

    # recreate the venv if a different python version is forced and incompatible
    # WARNING: This is experimental and might not work in all cases
    elif [[ -n "$forced_python" ]] && [[ ! -e "$venv/bin/$forced_python" ]]; then
        $quiet || warning "forced python version '$forced_python' differs from existing environment"
        $quiet || message wait "recreating virtual environment"
        rm -Rf "$venv"
        "$forced_python" -m venv "$venv" --prompt "$venv_prompt"
        update=true
        $quiet || message check 'new python virtual environment created:'
        $quiet || message  "     $venv"

    # if the venv exists and the python version is correct, do nothing
    else
        $quiet || message "virtual environment already exists"
    fi

    HLP__LAST_VENV=$venv
    if [[ $update == 'true' ]]; then
        virtual_python "$venv" !pip install --upgrade pip
        [[ $requirements ]] && virtual_python "$VENV_DIR" !pip install -r "$requirements_file"
    fi
}


# Ensures the specified Python virtual environment is active.
#
# Usage:
#   require_active_venv [--quiet] <venv>
#
# Parameters:
#   * --quiet: (optional) if set, suppress output.
#   * venv: the path to the Python virtual environment to be activated.
#
# Example:
#   require_active_venv "/path/to/my-venv"
#   require_active_venv --quiet "/path/to/my-venv"
#
require_active_venv() {

    # process all initial parameters that start with '-'
    local quiet=false
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
        --quiet) quiet=true ;;
        -)       shift ; break ;;
        *)       fatal_error "require_active_venv does not support the parameter '$1'"  ;;
        esac
        shift
    done

    local venv=$1

    if is_venv_active "$venv"; then
        $quiet || message check "virtual environment already activated"
        return
    fi

    if [[ $? -eq 2 ]]; then
        fatal_error \
            "function require_active_venv() is unable to switch between virtual environments" \
            "This is an internal error likely caused by a mistake in the code"
    fi

    $quiet || message wait 'activating virtual environment'
    # shellcheck source=/dev/null
    source "$venv/bin/activate"
    $quiet || message check 'virtual environment activated'
}


# Runs a command or Python script within the a virtual environment.
#
# Usage:
#   virtual_python [<venv>] <command> [args...]
#
# Parameters:
#   - venv (optional):
#      The path to the Python virtual environment to use.
#      If not provided, the function will use the last used virtual environment.
#   - command:
#      - "CONSOLE": Opens an interactive shell in the virtual environment.
#      - Command starting with "!": Runs the specified System command.
#      - Otherwise                : Runs the specified Python script.
#   - args...:
#      Additional arguments to pass to the command or Python script.
#
# Returns:
#   The exit status of the executed command or Python script.
#
# Examples:
#   virtual_python "/path/to/my_venv" CONSOLE
#   virtual_python "/path/to/my_venv" my_script.py arg1 arg2
#   virtual_python "/path/to/my_venv" "!pip install numpy"
#   virtual_python my_script.py  # Uses the last used virtual environment
#
virtual_python() {
    local venv command

    if [[ -d "$1" ]]; then
        # if the first parameter is a directory, it's assumed to be the `venv`
        venv=$1
        command=$2
        shift 2
    else
        # if the first parameter is NOT a directory, the `venv` will be the last used one
        venv=$HLP__LAST_VENV
        command=$1
        shift 1
    fi

    [[ "$venv" ]] || \
        fatal_error "The venv parameter is not previously defined"

    [[ -f "$venv/bin/activate" ]] || \
        fatal_error "The virtual environment '$venv' does not exist." \
                    "Please ensure the virtual environment is correctly installed."

    # handle the CONSOLE command
    if [[ $command == 'CONSOLE' ]]; then
        # shellcheck source=/dev/null
        source "$venv/bin/activate" || return 1
        exec /bin/bash --norc -i
        # the exec command replaces the current shell, so the
        # following line is unreachable, it's included for clarity
        return $?
    fi

    # ensure that the virtual environment is activated and ready,
    # and store it as the last one used for future reference
    require_active_venv --quiet "$venv"
    HLP__LAST_VENV=$venv

    # if no command was provided, there is nothing to execute
    # (the function was simply used to activate the virtual environment)
    if [[ -z "$command" ]]; then
        return 0

    # if the command starts with "!", execute it as a python script
    elif  [[ "$command" == "!"* ]]; then
        "${command:1}" "$@"

    # otherwise, execute it as a normal linux command
    else
        python "$command" "$@"
    fi
}
