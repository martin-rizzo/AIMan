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
INSTALL_PIPELINES=true

#============================================================================
# Installs the project in the specified environment.
#
# Parameters:
#   - venv        : the path to the Python virtual environment to use
#   - project_dir : the path to the local project directory
#   - repo        : the URL of the project's Git repository
#   - hash        : the Git commit hash or tag to use
#
# Globals:
#   - PROJECT_NAME : the short name of the project, e.g. "webui"
#   - PROJECT_PORT : the port where the app should listen, empty = default
#
function install() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    # Python  >= 3.11
    # Node.js >= 20.10
    require_system_command git npm python3.11
    require_venv "$venv" python3.11
    clone_repository "$repo" "$hash" "$project_dir"

    #-------------------- INSTALLING ---------------------#
    safe_chdir "$project_dir"

    # copying required .env file
    cp -RPp .env.example .env

    # building frontend using node
    npm install
    npm run build

    # install backend dependencies
    safe_chdir "$project_dir"
    virtual_python !pip install --upgrade pip
    virtual_python !pip install -r backend/requirements.txt -U

    #------------------ ADD PIPELINES ------------------#
    if [[ $INSTALL_PIPELINES == true ]]; then

        # install pipelines
        mkdir "$project_dir"
        git clone https://github.com/open-webui/pipelines.git
        virtual_python !pip install -r pipelines/requirements.txt

    fi
}

#============================================================================
# Launches the project application in the specified environment.
#
# Parameters:
#   - venv        : the path to the Python virtual environment to use
#   - project_dir : the path to the local project directory
#   - repo        : the URL of the project's Git repository
#   - hash        : the Git commit hash or tag to use
#
# Globals:
#   - PROJECT_NAME : the short name of the project, e.g. "webui"
#   - PROJECT_PORT : the port where the app should listen, empty = default
#
function launch() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    require_venv "$venv" python

    #----------------- OPTIONS -----------------#
    local options=() port='' port_message=''
    if [[ $PROJECT_PORT ]]; then
        port=$PROJECT_PORT
        port_message="on port $PROJECT_PORT"
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$project_dir/backend"
    message "changed working directory to $PWD"
    message "launching Open WebUI application $port_message"
    message "./start.sh" "${options[@]}" "$@"
    message
    virtual_python !./start.sh "${options[@]}" "$@"
}
