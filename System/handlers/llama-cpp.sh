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

# Validates that the libcurl development files are installed on the system.
# If not, provides an error message with DNF installation instructions.
#
# Usage:
#   fedora_require_libcurl
#
# Example:
#   fedora_require_libcurl
#
fedora_require_libcurl() {
    # check if libcurl development package is registered in the system
    if ! pkg-config --exists libcurl 2>/dev/null; then
        fatal_error "libcurl-devel is not installed." \
"Install the curl development package via DNF:
      sudo dnf install libcurl-devel"
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
    PORT=$2
    #VENV=$3
    #PYTHON=$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
    SHARED_TMP_DIR=$8  #< temporary directory shared with other apps and users
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
    require_system_command pkg-config git cmake go # gcc-13 g++-13
    fedora_require_libcurl
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"

    # build llama.cpp from source code
    # https://github.com/ollama/ollama/blob/main/docs/development.md
    export CUDACXX
    CUDACXX=$(fedora_find_nvcc)
    rm -rf build
    cmake -B      build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="86" -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release --parallel "$(nproc)"

    ## MLX support for llama.cpp
    #rm -rf build
    #cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="86" -DGGML_MLX=ON -DCMAKE_BUILD_TYPE=Release
    #cmake --build build --config Release --parallel "$(nproc)"
}

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {
    local PORT=8081
    local LLAMA_SERVER="$LOCAL_DIR/build/bin/llama-server"
    local MODELS_PRESET="$HOME/llama-presets.ini"

    # ensure the shared folder exists
    [[ -d $SHARED_TMP_DIR ]] \
    || bug_report "init parameter 8: '$SHARED_TMP_DIR' is not a directory"

    # pipe is located in the shared folder to avoid permission issues
    local PIPE_FILE="$SHARED_TMP_DIR/llama_server_trigger"

    #------------- LLAMA.CPP OPTIONS -------------#
    local options=()
    local launching_extra_message=""
    options+=( --models-preset "$MODELS_PRESET" )
    options+=( --models-max 1 )

    if [[ $PORT ]]; then
        options+=( --port "$PORT" )
        launching_extra_message="on port $PORT"
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    message "changed working directory to $PWD"

    # create the named pipe and set open permissions
    rm -f "$PIPE_FILE"
    mkfifo "$PIPE_FILE"
    chmod 666 "$PIPE_FILE"

    # clean up files and process on exit
    # shellcheck disable=SC2329
    cleanup_on_exit() {
        rm -f "$PIPE_FILE"
        [[ -n "$LLAMA_PID" ]] && kill "$LLAMA_PID" 2>/dev/null
    }
    trap cleanup_on_exit SIGINT EXIT


    while true; do
        local key='' cmd=''

        # launch llama-server as a background job
        message "launching llama.cpp cli in router mode ${launching_extra_message}"
        message "$LLAMA_SERVER" "${options[@]}"
        "$LLAMA_SERVER" "${options[@]}" &
        LLAMA_PID=$!
        message "llama-server launched with PID: $LLAMA_PID"

        # print banner explaining all controls
        echo
        echo -e "${MAGENTA}╭─────────────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${MAGENTA}│${RESET} ${CYAN}⚙️  LLAMA-SERVER CONTROL PANEL${RESET}                                   ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}├─────────────────────────────────────────────────────────────────┤${RESET}"
        echo -e "${MAGENTA}│${RESET} ${GREEN}[r]${RESET} ${BOLD}Keyboard:${RESET} Restart the server immediately                    ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET} ${RED}[q]${RESET} ${BOLD}Keyboard:${RESET} Shut down and exit completely                     ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET} ${YELLOW}[IPC Trigger]${RESET} From another user/project run:                    ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}                                                                 ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}   echo \"restart\" > ${PIPE_FILE}${RESET}          ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}                                                                 ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}╰─────────────────────────────────────────────────────────────────╯${RESET}\n"

        while kill -0 "$LLAMA_PID" 2>/dev/null; do

            # check the pipe for external commands (100ms timeout)
            [[ -p "$PIPE_FILE" ]] && read -t 0.1 -r cmd <> "$PIPE_FILE" 2>/dev/null

            # check keyboard input (100ms timeout)
            read -t 0.1 -n 1 -r key
            [[ $key == "r" ]] && cmd="restart"
            [[ $key == "q" ]] && cmd="quit"

            if [[ "$cmd" == "quit" || "$cmd" == "restart" ]]; then
                kill "$LLAMA_PID" 2>/dev/null
                break
            fi

            # small sleep to prevent CPU spiking
            sleep 1

        done

        # wait as max 5 seconds to normally finish llama.cpp
        # and then kill any process of llama-server that may be stuck
        timeout 5s wait "$LLAMA_PID" 2>/dev/null
        pkill -9 -f llama-server

        if [[ $cmd == "quit" ]]; then
            echo -e "\nShutting down..." 
            return 0
        fi
    done
}
