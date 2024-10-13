#!/usr/bin/env bash
# File    : handlers/open-webui.sh
# Brief   : Manages the local copy of the "Open WebUI" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Oct 7, 2024
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

# Whether to install and configure the "Pipelines" framework
#  (https://github.com/open-webui/pipelines)
#  'true' is 100% recommended for enhanced functionality
INSTALL_PIPELINES=true

# Path to the 'pipelines' directory (relative to open-webui).
PIPELINES_REL_DIR="../open-webui-pipelines"


#--------------------------------- HELPERS ----------------------------------

# Launches three services within a screen session,
# each in a separate horizontally split panel.
launch_in_screen_session() {
    local session=$1 aiman=$2

    # check if a session name is provided.
    [[ -n "$session" ]] ||
        bug_report "The 'launch_in_screen_session()' function requires a session name as the first argument"

    screen -S "$session" -X focus top
    screen -S "$session" -X screen -t   'OLLAMA'  "$aiman" ollama.launch

    screen -S "$session" -X split
    screen -S "$session" -X focus next
    screen -S "$session" -X screen -t 'PIPELINES' "$aiman" open-webui.launch --pipelines

    sleep 1
    screen -S "$session" -X split
    screen -S "$session" -X focus next
    screen -S "$session" -X screen -t   'WEBUI'   "$aiman" open-webui.launch --webui
}


#============================================================================
# Initialize the project handler
#
# Usage:
#   _init_ NAME PORT VENV PYTHON LOCAL_DIR REMOTE_URL REMOTE_HASH
#
# Parameters:
#   - NAME        : short name of the project (e.g. "webui")
#   - PORT        : port number where the app should listen, empty = default
#   - VENV        : path to the Python virtual environment to use
#   - PYTHON      : name (or path to) the Python interpreter to use (e.g. "python3.11")
#   - LOCAL_DIR   : path to the local project directory
#   - REMOTE_URL  : URL of the project's Git repository
#   - REMOTE_HASH : Git commit hash or tag of the recommended version

_init_() {
    #NAME=$1
    #PORT=$2
    VENV=$3
    PYTHON=python3.11  # =$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
}

#============================================================================
# Installs the project in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

    # Python  >= 3.11
    # Node.js >= 20.10
    require_system_command git npm "$PYTHON"
    require_venv "$VENV" "$PYTHON"
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"

    #-------------------- INSTALLING ---------------------#
    safe_chdir "$LOCAL_DIR"

    # copying required .env file
    cp -RPp .env.example .env

    # building frontend using nodejs
    npm install
    npm run build

    # install backend dependencies
    safe_chdir "$LOCAL_DIR"
    virtual_python !pip install --upgrade pip
    virtual_python !pip install -r backend/requirements.txt -U

    #------------------ ADD PIPELINES ------------------#
    if [[ $INSTALL_PIPELINES == true ]]; then

        # install pipelines
        mkdir -p   "$LOCAL_DIR/$PIPELINES_REL_DIR"
        safe_chdir "$LOCAL_DIR/$PIPELINES_REL_DIR"
        git clone https://github.com/open-webui/pipelines.git .
        virtual_python !pip install -r requirements.txt

    fi
}

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {

    # default service to launch is SCREEN with 3 panels: ollama/pipelines/webui
    local launch='screen'
    local options=()

    # override the default service to launch based on the first argument
    case $1 in
        '--ollama')
            launch='ollama'
            shift
            ;;
        '--pipelines')
            launch='pipelines'
            shift
            ;;
        '--webui')
            launch='webui'
            shift
            ;;
        '--screen')
            launch='screen'
            shift
            ;;
    esac

    # port selection
    # (currently not used, but kept for future expansion).
    #local port=''
    local port_message=''


    #-- LAUNCHING THE USER-SPECIFIED SERVICE -------------#

    # launch "Ollama"
    if [[ $launch == 'ollama' ]]; then
        "$AIMAN" ollama.launch


    # launch "Pipelines" (a ui-agnostic openai api plugin framework)
    elif [[ $launch == 'pipelines' ]]; then
        if [[ $INSTALL_PIPELINES != true ]]; then
            fatal_error "Automatic installation of Pipelines with Open WebUI is disabled" \
                "This is due to 'INSTALL_PIPELINES' is set to '$INSTALL_PIPELINES 'in System/handlers/open-webui.sh"
        fi
        require_venv "$VENV" "$PYTHON"
        safe_chdir "$LOCAL_DIR/$PIPELINES_REL_DIR"
        message "working directory changed to: $PWD"
        message "launching Pipelines $port_message"
        message "./start.sh" "${options[@]}" "$@"
        message
        virtual_python !./start.sh "${options[@]}" "$@"


    # launch "Open WebUI"
    elif [[ $launch == 'webui' ]]; then
        require_venv "$VENV" "$PYTHON"
        safe_chdir "$LOCAL_DIR/backend"
        message "working directory changed to: $PWD"
        message "launching Open WebUI application $port_message"
        message "./start.sh" "${options[@]}" "$@"
        message
        virtual_python !./start.sh "${options[@]}" "$@"


    # launch WebUI + Pipelines+ Ollama in three separate screen regions
    elif [[ $launch == 'screen' ]]; then
        local screen_session='open-webui'
        require_system_command screen
        launch_in_screen_session "$screen_session" "$AIMAN" &
        screen               -S  "$screen_session" -t "LAUNCHING" sleep 5


    fi
}

#============================================================================
# Removes any extra files that were installed outside the main project.
#
# Usage:
#   _init_ ...
#   cmd_remove_extra [user_args]
#
cmd_remove_extra() {

    if [[ $INSTALL_PIPELINES == true ]]; then
        echox wait  "Removing sub-project 'open-webui-pipelines'"
        rm -rf "${LOCAL_DIR:?}/${PIPELINES_REL_DIR:?}"
        echox check "Sub-project 'open-webui-pipelines' has been removed."
    fi
}


