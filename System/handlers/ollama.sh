#!/usr/bin/env bash
# File    : ollama-handler.sh
# Brief   : Manages the local copy of the "ollama" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Sep 28, 2024
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
# ATTENTION:
# !! Prerequisites: CUDA Toolkit and GCC 13 are required.
# !! Installation instructions are provided below. Proceed at your own risk.
#
# CUDA Toolkit Installation (Fedora 39+):
#    > sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora39/x86_64/cuda-fedora39.repo
#    > sudo dnf clean all
#    > sudo dnf install cuda-toolkit-12
#
# GCC 13 Installation (Fedora 39+):
#    > sudo dnf install gcc-13 gcc13-c++
# add symbolic links
#    > sudo ln -s /usr/bin/gcc-13/usr/local/cuda/bin/gcc
#    > sudo ln -s /usr/bin/g++-13 /usr/local/cuda/bin/g++
#
#

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

    require_system_command git cmake go gcc-13 g++-13
    #require_storage_dir

    clone_repository "$repo" "$hash" "$project_dir"
    safe_chdir "$project_dir"

    # build ollama from source code
    go generate ./...
    go build .
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

    # default ollama port configuration
    local port=11434 port_message=''

    # attempt to override the default port based on project configuration
    if [[ $PROJECT_PORT ]]; then
        message "Cannot bind to $PROJECT_PORT. Ollama port configuration not yet implemented"
        # port=$PROJECT_PORT
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$project_dir"
    [[ $port ]] && port_message="on port $port"
    message "changed working directory to $PWD"
    message "launching Ollama Server $port_message"
    message
    mkdir -p "$MODELS_OLLAMA_DIR"
    OLLAMA_HOST="127.0.0.1:$port" OLLAMA_MODELS="$MODELS_OLLAMA_DIR" ./ollama serve
}
