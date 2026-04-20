#!/usr/bin/env bash
# File    : handlers/01_empty.sh
# Brief   : Empty example of a application handler.
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
#   - NAME        : short name of the application (e.g. "webui")
#   - PORT        : port number where the app should listen, empty = default
#   - VENV        : path to the Python virtual environment to use
#   - PYTHON      : name (or path to) the Python interpreter to use (e.g. "python3.11")
#   - LOCAL_DIR   : path to the local application directory
#   - REMOTE_URL  : URL of the application's Git repository
#   - REMOTE_HASH : Git commit hash or tag of the recommended version
#
_init_() {
    NAME=$1
    PORT=$2
    VENV=$3
    PYTHON=$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
}

#============================================================================
# Installs the application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

    ## the system commands required by this application
    #require_system_command git wget

    ## if this application requires a storage directory
    ## (which is automatically reserved in "<AIMAN>/Storage/<application-name>")
    #require_storage_dir

    ## if this application requires running into a virtual environment
    ## (usually any python-based application needs one)
    #require_venv "$VENV" "$PYTHON"

    # clone repository from remote URL to local directory
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"

    ## usually not needed but left as an example of generating
    ## symlinks to common directories shared by all applications
    #require_symlink 'outputs'    "$OUTPUT_DIR"                   --convert-dir
    #require_symlink 'styles.csv' "$MODELS_STYLES_DIR/styles.csv" --move-file


    ## usually not needed but left as an example of generating default configuration files
    #local config_file="$LOCAL_DIR/config.json"
    #echox wait "generating default configuration"
    #echo "
    #{
    #     \"auto_launch_browser\": \"$AUTO_LAUNCH_BROWSER\",
    #     \"export_for_4chan\": $EXPORT_FOR_4CHAN
    #}
    #" > "$config_file"
    #echo "$config_file"

    #--------------- INSTALLING ----------------#
    safe_chdir "$LOCAL_DIR"
    echox wait "installing '<Application Nane>'"
    virtual_python launch.py --no-download-sd-model --exit
}

#============================================================================
# Launches the application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {
    echo "cmd_launch not implemented yet"

    ## if this application requires running into a virtual environment
    ## (usually any python-based application needs one)
    #require_venv "$VENV" "$PYTHON"

    #--------- CONFIGURE USER SETTINGS ---------#
    #local options=()

    ## general application settings parameters
    #options+=( --theme dark  )
    #options+=( --port "$PORT" )

    #-------------- OPTIMIZATIONS --------------#
    #local optimizations=()

    ## optimizations parameters for launching the application
    ## could be things like --always-gpu, --cuda-malloc, etc depending on the application
    #optimizations+=( --always-gpu )

    #------ REDIRECT DIRECTORIES TO AIMAN ------#
    #local directories=()

    ## parameters to redirect application directories to common AIMAN directory
    #directories+=( --ckpt-dir "$MODELS_STABLEDIFFUSION_DIR" )

    ## launching the application
    ## `virtual_python` launches the command in the virtual environment selected with `require_venv`
    #safe_chdir "$LOCAL_DIR"
    #echox check "changed working directory to $PWD"
    #echox wait  "launching <Application Name>"
    #virtual_python launch.py "${options[@]}" "${optimizations[@]}" "${directories[@]}" "$@"
}


#============================================================================
# Removes any extra files that were installed outside the main application.
#
# Usage:
#   _init_ ...
#   cmd_remove_extra [user_args]
#
cmd_remove_extra() {
    echo "cmd_remove_extra not implemented yet"
}


