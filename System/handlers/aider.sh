#!/usr/bin/env bash
# File    : handlers/aider.sh
# Brief   : Handler for the Aider application
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 19, 2026
# Repo    : https://github.com/martin-rizzo/AIMan
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                    AIMan
#        A basic package management system for AI open source applications
#
#     Copyright (c) 2023-2026 Martin Rizzo
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


#============================================================================
# Initialize the application handler
#
# Usage:
#   _init_ NAME PORT VENV PYTHON LOCAL_DIR REMOTE_URL REMOTE_HASH
#
# Parameters:
#   1- NAME        : short name of the application (e.g. "aider")
#   2- PORT        : port number where the app should listen, empty = default
#   3- VENV        : path to the Python virtual environment to use
#   4- PYTHON      : name (or path to) the Python interpreter to use (e.g. "python3.11")
#   5- LOCAL_DIR   : path to the local application directory
#   6- REMOTE_URL  : URL of the application's Git repository
#   7- REMOTE_HASH : Git commit hash or tag of the recommended version
#
_init_() {
    NAME=$1
    PORT=$2                    # Not used by Aider
    VENV=$3
    PYTHON=$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
}

#============================================================================
# Installs the Aider application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {
    require_system_command git pip "$PYTHON"

    echox wait "Cloning https://github.com/Aider-AI/aider"
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"

    # create virtual environment for Aider
    safe_chdir "$LOCAL_DIR"
    require_venv "$VENV" "$PYTHON"
    echox wait "Installing Aider in editable mode"
    virtual_python !pip install -e .
}
#============================================================================
# Launches Aider using the configured environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {
    require_venv "$VENV" "$PYTHON"
    safe_chdir "$LOCAL_DIR"

    # check if launching with a ollama model ("--model ollama/<model-name>")
    if [[ "$1" == "--model" && "$2" == ollama/* ]]; then
        if [[ -z "${OLLAMA_API_BASE}" ]]; then
            fatal_error \
                "OLLAMA_API_BASE environment variable must be defined for ollama models" \
                'you can define "export OLLAMA_API_BASE=http://localhost:11434" in your bashrc'
        fi
        echox wait "launching Aider with ollama model: $2"
        virtual_python -m aider --no-git "$@"
        exit 0
    fi

    echox wait "launching Aider"
    # Run Aider using the Python interpreter in the correct environment
    virtual_python -m aider --no-git "$@"
}
#============================================================================
# Removes any extra files or directories created by Aider outside the main application.
#
# Usage:
#   _init_ ...
#   cmd_remove_extra [user_args]
#
cmd_remove_extra() {
    echo "cmd_remove_extra not implemented for Aider"
}