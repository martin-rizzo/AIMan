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

# Check if AIMAN variable is set, otherwise exit with an error
AIMAN=${AIMAN:?}

# Whether to install and configure the "Pipelines" framework
#  (https://github.com/open-webui/pipelines)
#  'true' is 100% recommended for enhanced functionality
INSTALL_PIPELINES=true

# Path to the 'pipelines' project directory (relative to open-webui).
PIPELINES_REL="../open-webui-pipelines"

# Directory to store 'pipelines' workflows.
# This will be created if it doesn't exist.
PIPELINES_WORKFLOWS_DIR="$MODELS_DIR/Pipelines"

# Port number for the 'pipelines' server
PIPELINES_PORT=9099


#--------------------------------- HELPERS ----------------------------------

# Installs a pipeline script into the '$PIPELINES_WORKFLOWS_DIR' directory.
#
# Usage: install_pipelines <pipeline_name> <path_to_script>
#
# Parameters:
#   pipeline_name  - The name of the pipeline, ej: "Google GenAI Manifold Pipeline"
#   path_to_script - Full path to the script file that needs to be installed.
#
install_pipelines() {
    local pipeline_name=$1 pipeline_script=$2
    local filename

    [[ -n "$pipeline_script" ]] \
      || bug_report "install_pipelines() did not receive any script to install"
    [[ -f "$pipeline_script" ]] \
      || bug_report "install_pipelines() did not find the script '$pipeline_script'"

    # if no pipeline name was provided, set it to the basename of the script
    filename=$(basename "$pipeline_script")
    if [[ -z $pipeline_name ]]; then
        pipeline_name=$filename
    fi

    # check if a file with the same name already exists in the pipelines directory
    if [[ -e "$PIPELINES_WORKFLOWS_DIR/$filename" ]]; then
        echox check "$filename already installed"
        return
    fi

    echox wait "Installing $pipeline_name"
    mkdir -p "$PIPELINES_WORKFLOWS_DIR"
    cp "$pipeline_script" "$PIPELINES_WORKFLOWS_DIR"
}

# Launches three services within a screen session,
# each in a separate horizontally split panel.
#
# Usage: launch_in_screen_session <session_name> <aiman_command>
#
# Parameters:
#   session - The name of the 'screen' session to be created or reused.
#   aiman   - The full path to the 'aiman' command used to start the services.
#
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
    screen -S "$session" -X screen -t   'WEBUI'   "$aiman" open-webui.launch --webui --close-screen-on-exit
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
    NAME=$1
    #PORT=$2
    VENV=$3
    PYTHON=python3.11  # =$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
    PIPELINES_LOCAL_DIR="${LOCAL_DIR:?}/${PIPELINES_REL:?}"
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

    #---------------- INSTALL OPEN-WEBUI -----------------#
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

    #----------------- INSTALL PIPELINES -----------------#

    # if the installation of pipelines is not required, return early
    [[ $INSTALL_PIPELINES != true ]] && return

    # define source paths to the predefined pipeline examples
    # shellcheck disable=SC2034
    local filters="$PIPELINES_LOCAL_DIR/examples/filters"      \
          pipelines="$PIPELINES_LOCAL_DIR/examples/pipelines"  \
          scaffolds="$PIPELINES_LOCAL_DIR/examples/scaffolds"

    # MAIN
    mkdir -p   "$PIPELINES_LOCAL_DIR"
    safe_chdir "$PIPELINES_LOCAL_DIR"
    git clone https://github.com/open-webui/pipelines.git .
    virtual_python !pip install -r requirements.txt

    # install specific scripts that come predefined with PIPELINES
    install_pipelines "Google GenAI Manifold Pipeline" "$pipelines/providers/google_manifold_pipeline.py"
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
    local close_screen=false
    local options=()

    # process command-line arguments que especifican the service to launch
    # and whether to close the screen session.
    while [[ $# -gt 0 ]]; do
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
            # internally used to close the 'screen' session on exit
            '--close-screen-on-exit')
                close_screen=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # port selection
    # (currently not used, but kept for future expansion).
    #local port=''
    local port_message=''


    #-- LAUNCHING THE USER-SPECIFIED SERVICE -------------#
    local screen_session="$NAME-ss"

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
        safe_chdir "$PIPELINES_LOCAL_DIR"
        message "working directory changed to: $PWD"
        message "launching Pipelines $port_message"
        message "./start.sh" "${options[@]}" "$@"
        message
        mkdir -p "$PIPELINES_WORKFLOWS_DIR"
        export PIPELINES_DIR="$PIPELINES_WORKFLOWS_DIR"
        export PORT="$PIPELINES_PORT"
        virtual_python !./start.sh "${options[@]}" "$@"

    # launch "Open WebUI"
    elif [[ $launch == 'webui' ]]; then
        echo -ne "\033]0; Open WebUI 👋\a"
        require_venv "$VENV" "$PYTHON"
        safe_chdir "$LOCAL_DIR/backend"
        message "working directory changed to: $PWD"
        message "launching Open WebUI application $port_message"
        message "./start.sh" "${options[@]}" "$@"
        message
        # export GLOBAL_LOG_LEVEL="DEBUG"
        export HOST="127.0.0.1"
        export PORT="8080"
        virtual_python !./start.sh "${options[@]}" "$@"


    # launch WebUI + Pipelines+ Ollama in three separate screen regions
    elif [[ $launch == 'screen' ]]; then
        require_system_command screen
        launch_in_screen_session "$screen_session" "$AIMAN" &
        screen               -S  "$screen_session" -t "LAUNCHING" sleep 5
    fi


    # on service completion,
    # close the 'screen' session if requested
    if [[ $close_screen == true ]]; then
        screen -S "$screen_session" -X quit
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
        rm -rf "${PIPELINES_LOCAL_DIR:?}"
        echox check "Sub-project 'open-webui-pipelines' has been removed."
    fi
}


