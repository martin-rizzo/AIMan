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

#--------------------------------- HELPERS ----------------------------------

# Launches/closes an Open WebUI and Llama.cpp session using tmux.
#
# This function enables key bindings for window navigation (F1/F2) and mouse
# scroll support. It then starts two windows: one running "llama.cpp" and
# another running "Open-WebUI" interface, attaching the user to that session.
# If the command is "close", it terminates the specified session.
#
# Usage:
#   control_owui_and_llamacpp <command> <session_name>
#
# Parameters:
#   command     : The action to perform. Must be either "launch" or "close".
#   session_name: The name of the tmux session to create or manage.
#
# Example:
#   control_owui_and_llamacpp launch ai_session
#   control_owui_and_llamacpp close  ai_session
#
function control_owui_and_llamacpp() {
    local command=$1 session=$2
    require_system_command tmux

    if [[ $command == "launch" ]]; then

        # create a temporary configuration file for tmux
        local TMUX_CONF
        TMUX_CONF=$(mktemp)

        # enable mouse support (scrolling and clicking)
        echo "set -g mouse on" >> "$TMUX_CONF"

        # bind "PageUp" to enter copy mode and scroll up
        echo "bind-key -n PageUp copy-mode -u" >> "$TMUX_CONF"

        # enable natural PageDown behavior within copy-mode
        echo "bind-key -T copy-mode-vi PageDown send-keys -X page-down" >> "$TMUX_CONF"

        # force tmux to start window indexing from 1
        echo "set -g base-index 1" >> "$TMUX_CONF"

        # define window navigation with "F1" and "F2" keys
        echo "bind-key -n F1 select-window -t :1" >> "$TMUX_CONF"
        echo "bind-key -n F2 select-window -t :2" >> "$TMUX_CONF"

        # start the session in detached mode with "llama.cpp"
        # and create the second window for "Open-WebUI"
        # attaching the session to the current terminal
        tmux -f "$TMUX_CONF" new-session -d -s "$session" -n "Llama.cpp"  "$AIMAN launch open-webui --llama-cpp --close-tmux-on-exit"
        tmux new-window                     -t "$session" -n "Open-WebUI" "$AIMAN launch open-webui --webui --close-tmux-on-exit"
        tmux attach-session -t "$session"

        # remove the temporary configuration file after connection is established
        rm -f "$TMUX_CONF"

    elif [[ $command == "close" ]]; then
        tmux kill-session -t "$session"

    # report an error if an unknown command is provided
    else
        bug_report "Invalid command '$command' in control_owui_and_llamacpp() function."

    fi
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
}

#============================================================================
# Installs the project in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

    # Python >= 3.12 // Node.js >= 20.10
    require_system_command git npm "$PYTHON"
    require_storage_dir
    require_venv "$VENV" "$PYTHON"

    # clone the repository converting the directories that must be preserved
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR/backend"
    mkdir -p               "$CONFIG_DIR/open-webui/data"
    require_symlink 'data' "$CONFIG_DIR/open-webui/data" --convert-dir

    #---------------- INSTALL OPEN-WEBUI -----------------#
    safe_chdir "$LOCAL_DIR"

    # copying required .env file
    cp -RPp .env.example .env

    # building frontend using nodejs
    npm install --force
    npm run build

    safe_chdir "$LOCAL_DIR"

    # You must have Python 3.11 development headers and MariaDB C connector installed
    # sudo dnf install python3.11-devel mariadb-connector-c-devel    

    # hack for ddgs version
    sed -i 's/ddgs==9.11.2/ddgs>=9.11.2/g' backend/requirements.txt

    # install backend dependencies
    virtual_python !pip install --upgrade pip
    virtual_python !pip install -r backend/requirements.txt -U

}

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {

    # default service to launch is TMUX with panels (webui + llama.cpp?)
    local launch='multi'
    local close_tmux=false
    local options=()

    # process command-line arguments that specify the service to launch
    # and whether to close the tmux session
    while [[ $# -gt 0 ]]; do
        case $1 in
            '--webui' | '--ui' | '-w')
                launch='webui'
                shift
                ;;
            '--llama-cpp' | '--llm' | '-l')
                launch='llama.cpp'
                shift
                ;;
            '--ollama' | '--ollm' | '-o')
                launch='ollama'
                shift
                ;;
            '--multi')
                launch='multi'
                shift
                ;;
            '--gnome')
                launch='gnome-terminal'
                shift
                ;;
            '--close-tmux-on-exit')
                # internally used to close the 'tmux' session on exit
                close_tmux=true
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
    local tmux_session="$NAME-tmux"

    # launch "Open WebUI"
    if [[ $launch == 'webui' ]]; then
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
        #export GLOBAL_LOG_LEVEL=DEBUG
        virtual_python !./start.sh "${options[@]}" "$@"

    # launch "Ollama"
    elif [[ $launch == 'ollama' ]]; then
        "$AIMAN" launch ollama

    # launch "llama.cpp"
    elif [[ $launch == 'llama.cpp' ]]; then
        "$AIMAN" launch llama.cpp

    # launch WebUI +  Ollama in two separate tmux windows
    elif [[ $launch == 'multi' ]]; then
        control_owui_and_llamacpp launch "$tmux_session"

    # launch WebUI + Ollama in three separate terminal tabs (gnome)
    elif [[ $launch == 'gnome-terminal' ]]; then
        require_system_command gnome-terminal
        gnome-terminal --tab -t OLLAMA     -- "$AIMAN" launch open-webui --ollama
        gnome-terminal --tab -t OPEN-WEBUI -- "$AIMAN" launch open-webui --webui

    fi

    # on service completion,
    # close the `tmux` session if requested
    [[ $close_tmux == true ]] && control_owui_and_llamacpp close "$tmux_session"
}

#============================================================================
# Removes any extra files that were installed outside the main project.
#
# Usage:
#   _init_ ...
#   cmd_remove_extra [user_args]
#
cmd_remove_extra() {
    :
}


