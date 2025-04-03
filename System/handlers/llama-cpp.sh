#!/usr/bin/env bash
# File    : handlers/llamacpp.sh
# Brief   : Manages the local copy of "llama.cpp"
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Feb 15, 2025
# Repo    : https://github.com/martin-rizzo/AIMan
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                    AIMan
#        A basic package management system for AI open source projects
#
#     Copyright (c) 2023-2025 Martin Rizzo
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
# Verificar que CUDA Toolkit esta instalado:
#    > ??? /usr/local/cuda/bin/nvcc
#

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
    PORT=$2
    #VENV=$3
    #PYTHON=$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
    #VERSION=$REMOTE_HASH
}

#============================================================================
# Installs the project in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

#     # iterate through the user arguments
#     while [[ $# -gt 0 ]]; do
#         local arg=$1
#         shift
#         case "$arg" in
#             -*)
#                 fatal_error "Error: Unknown option '$arg'"
#                 ;;
#         esac
#     done

    # clone llama.cpp repository
    require_system_command git cmake go gcc-13 g++-13
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"

    # build ollama from source code
    # https://github.com/ollama/ollama/blob/main/docs/development.md
    export CUDA_PATH=/usr/local/cuda/
    cmake -B      build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="86"
    cmake --build build --config Release
}

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {
    local model="/mnt/X/DISK_X/AI_Models/llama-cpp/Qwen2-VL-7B-Q4_K_M.gguf"
    local mmproj="/mnt/X/DISK_X/AI_Models/llama-cpp/mmproj-Qwen2-VL-7B-Instruct-abliterated-f16.gguf"
    local port=9100
    local port_message=''
    local llama_server="$LOCAL_DIR/build/bin/llama-server"

#     # attempt to override the default port based on project configuration
#     if [[ $PORT ]]; then
#         port=$PORT
#     fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    [[ $port ]] && port_message="on port $port"
    message "changed working directory to $PWD"
    message "launching llama.cpp server $port_message"
    message
    "$llama_server" -m "$model" --mmproj "$mmproj" --port "$port"
}
