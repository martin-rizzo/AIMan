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
# GCC 13 Installation (Fedora 39+):
#    > sudo dnf install gcc-13 gcc13-c++
# add symbolic links
#    > sudo ln -s /usr/bin/gcc-13/usr/local/cuda/bin/gcc
#    > sudo ln -s /usr/bin/g++-13 /usr/local/cuda/bin/g++
#
# Verificar que CUDA Toolkit esta instalado:
#    > ??? /usr/local/cuda/bin/nvcc
#


# Finds the path to nvcc command.
#
# This function searches for the 'nvcc' compiler in the PATH or in the default
# CUDA installation location. If not found, it provides an error message.
#
# Output:
#   Writes the absolute path to 'nvcc'
#
fedora_find_nvcc() {
    local cmd

    # check if 'nvcc' is already in PATH
    cmd=$(command -v nvcc 2>/dev/null)
    if [ $? -eq 0 ] && [ -x "${cmd}" ]; then
        echo "${cmd}"
        return
    fi

    # check if 'nvcc' is present in the default CUDA installation path
    cmd="/usr/local/cuda/bin/nvcc"
    if [ -x "${cmd}" ]; then
        echo "${cmd}"
        return
    fi

    # if 'nvcc' is not found, provide an error message and exit with a fatal error
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)
    fatal_error "CUDA Toolkit not found." \
"Please install it with:
  sudo dnf config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora${fedora_ver}/x86_64/cuda-fedora${fedora_ver}.repo
  sudo dnf install cuda-toolkit"
}


# Validates that the installed CUDA version meets the specified minimum requirement.
# If not, provides error message with installation instructions.
#
# Usage:
#   fedora_check_cuda_version [MIN_CUDA_VERSION]
#
# Parameters:
#   MIN_CUDA_VERSION (required): the minimum required CUDA major version.
#
# Example:
#   fedora_check_cuda_version 13
#
fedora_check_cuda_version() {
    local min_cuda_version="$1"
    local cuda_version
    local NVCC

    [[ -z "$min_cuda_version" || ! "$min_cuda_version" =~ ^[0-9]+$ ]] && \
        fatal_error "Minimum CUDA version must be a positive integer."

    # try to find nvcc command
    NVCC=$(fedora_find_nvcc)

    # MEJORADO: Se añade '2>/dev/null' por si el comando falla o no responde correctamente
    # extract CUDA major version (e.g., "13" from 'release 13.1')
    cuda_version=$($NVCC --version 2>/dev/null | grep -oP 'release \K[0-9]+')

    if [ -z "$cuda_version" ]; then
        warning "Failed to determine CUDA version."
        return 1
    fi

    message "Detected CUDA version: $cuda_version"
    if [ "$cuda_version" -lt "$min_cuda_version" ]; then
        fatal_error "CUDA version $min_cuda_version or newer is required. Found version $cuda_version."
    fi

    message "CUDA meets the required version ($min_cuda_version+)."
    return 0
}


# Validates that the installed cuDNN version meets a specified minimum requirement.
#
# Usage:
#   fedora_check_cudnn_version [MIN_CUDNN_VERSION]
#
# Parameters:
#   MIN_CUDNN_VERSION (required): the minimum required cuDNN major version.
#
# Example:
#   fedora_check_cudnn_version 9
#
fedora_check_cudnn_version() {
    [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]] && \
        fatal_error "Minimum cuDNN version must be a positive integer."

    local min_cudnn_version="$1"
    local cuDNN_header=""
    local cudnn_version=""

    # search for cuDNN version header
    for path in "/usr/local/cuda/include/cudnn_version.h" "/usr/include/cudnn_version.h"; do
        if [ -f "$path" ]; then
            cuDNN_header="$path"
            break
        fi
    done

    if [ -z "$cuDNN_header" ]; then
        fatal_error "cuDNN headers not found. Please verify your cuDNN installation." \
"Please install it using one of the following methods:

1. Manual Tarball Archive (Recommended for Fedora):
   - Download the cuDNN Linux Tarball from https://developer.nvidia.com/cudnn-downloads
   - Extract the downloaded archive:
         tar -xf cudnn-linux-x86_64-<your_version>-archive.tar.xz
   - Copy all include headers and library files to your CUDA installation directory:
     (replace '<extracted_dir>' with your extracted folder name)
        sudo cp    <extracted_dir>/include/* /usr/local/cuda/include/
        sudo cp -P <extracted_dir>/lib/*     /usr/local/cuda/lib64/
   - Grant standard read access permissions to the copied files:
       sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*

2. Enterprise Linux RPM Alternative:
   - Select the 'RHEL' distribution option on the NVIDIA download site.
   - Download the RPM local installer file matching your target CUDA base version.
   - Install the local package directly via package management:
     sudo dnf localinstall ./cudnn-local-repo-rhel*.rpm"
    fi

    # extract major version from CUDNN_MAJOR definition securely
    cudnn_version=$(grep -i '#define CUDNN_MAJOR' "$cuDNN_header" | awk '{print $3}' | tr -d '\r')

    if [ -z "$cudnn_version" ]; then
        warning "Failed to read cuDNN version from $cuDNN_header"
        return 1
    fi

    message "Detected cuDNN version: $cudnn_version"

    # compare with minimum required version
    if [ "$cudnn_version" -lt "$min_cudnn_version" ]; then
        fatal_error "cuDNN version $min_cudnn_version or higher is required. Found version $cudnn_version."
    fi

    message "cuDNN meets the required version ($min_cudnn_version+)."
    return 0
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
    PORT=$2
    VENV=$3
    PYTHON=$4
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

    message "Installing $NAME..."
    fedora_check_cuda_version 13
    fedora_check_cudnn_version 9

    # clone llama.cpp repository
    require_system_command git cmake go gcc-13 g++-13
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"

    # build llama.cpp from source code
    # https://github.com/ollama/ollama/blob/main/docs/development.md
    # export CUDA_PATH=/usr/local/cuda/
    # cmake -B      build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="86"
    # cmake --build build --config Release
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
