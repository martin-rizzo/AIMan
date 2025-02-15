#!/usr/bin/env bash
# File    : handlers/ollama.sh
# Brief   : Manages the local copy of "ollama"
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
# Verificar que CUDA Toolkit esta instalado:
#    > ??? /usr/local/cuda-12/bin/nvcc
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
    #PYTHON=python3.11 # =$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
    VERSION=$REMOTE_HASH
}

#============================================================================
# Installs the project in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

    # valid presets are defined in:
    # https://github.com/ollama/ollama/blob/main/CMakePresets.json
    PRESET='CUDA' # default value

    # iterate through the user arguments
    while [[ $# -gt 0 ]]; do
        local arg=$1
        shift
        case "$arg" in
            --cpu)
                PRESET='CPU'
                ;;
            --cuda)
                PRESET='CUDA'
                ;;
            --cuda11)
                PRESET='CUDA 11'
                ;;
            --cuda12)
                PRESET='CUDA 12'
                ;;
            --jetpack5)
                PRESET='JetPack 5'
                ;;
            --jetpack6)
                PRESET='JetPack 6'
                ;;
            --rocm)
                PRESET='ROCm'
                ;;
            --rocm6)
                PRESET='ROCm 6'
                ;;
            --4060 | --4070 | --4080 | --4090 )
                PRESET='CUDA'
                export CMAKE_CUDA_ARCHITECTURES='89'
                ;;
            --3060 | --3070 | --3080 | --3090 )
                PRESET='CUDA'
                export CMAKE_CUDA_ARCHITECTURES='86'
                ;;
            --1650 | --2060 | --2070 | --2080 )
                PRESET='CUDA'
                export CMAKE_CUDA_ARCHITECTURES='75'
                ;;
            -*)
                fatal_error "Error: Unknown option '$arg'"
                ;;
        esac
    done
    message "selected PRESET = '$PRESET'"


    # clone ollama repository
    require_system_command git cmake go gcc-13 g++-13
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"

    # set ollama version
    sed -i 's/"0.0.0"/"'"$VERSION"'"/g' version/version.go

    # build ollama from source code
    # https://github.com/ollama/ollama/blob/main/docs/development.md
    export CUDA_PATH=/usr/local/cuda/
    cmake -B      build --preset "$PRESET"
    cmake --build build --preset "$PRESET" --config Release
}

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {

    # default ollama port configuration
    local port=11434 port_message=''

    # attempt to override the default port based on project configuration
    if [[ $PORT ]]; then
        message "Cannot bind to $PORT. Ollama port configuration not yet implemented"
        # port=$PORT
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    [[ $port ]] && port_message="on port $port"
    message "changed working directory to $PWD"
    message "launching Ollama Server $port_message"
    message
    mkdir -p "$MODELS_OLLAMA_DIR"

    export OLLAMA_HOST="127.0.0.1:$port"
    export OLLAMA_MODELS="$MODELS_OLLAMA_DIR"
    #export OLLAMA_DEBUG=1
    go run . serve
}
