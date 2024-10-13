#!/usr/bin/env bash
# File    : handlers/invoke.sh
# Brief   : Manages the local copy of "Invoke"
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
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
    PYTHON=python3.11 # =$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7
}


# function install() {
#     local venv=$1 project_dir=$2 repo=$3 hash=$4
#     shift 4
#
#     require_system_command git
#     require_storage_dir
#     require_venv "$venv"
#
#     clone_repository "$repo" "$hash" "$project_dir"
#     safe_chdir "$project_dir"
#
#     # export INVOKEAI_ROOT=$project_dir
#
#     # NVIDIA GPU
#     #virtual_python "$venv" !pip install -e .[xformers] --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu117
#
#     ## AMD GPU
#     #virtual_python "$venv" !pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/rocm5.4.2
#
#     ## CPU
#     #virtual_python "$venv" !pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/cpu
#
#     ## configure / downloads models
#     #virtual_python "$venv" !invokeai-configure --root_dir "$project_dir"
#
#     ## launch
#     #virtual_python "$venv" !invokeai --web --root_dir "$project_dir"
#
# }

#============================================================================
# Installs the project in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_install [user_args]
#
cmd_install() {

    require_system_command git pnpm node "$PYTHON"
    require_storage_dir
    require_venv "$VENV" "$PYTHON"

    # obtener una copia local
    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"

#     # crear estructura de directorios para los modelos
#     safe_chdir "$LOCAL_DIR/models"
#     require_symlink 'checkpoints'   "$MODELS_STABLEDIFFUSION_DIR" --convert-dir
#     require_symlink 'clip'          "$MODELS_TEXTENCODER_DIR"     --convert-dir
#     require_symlink 'controlnet'    "$MODELS_CONTROLNET_DIR"      --convert-dir
#     require_symlink 'embeddings'    "$MODELS_EMBEDDINGS_DIR"      --convert-dir
#     require_symlink 'hypernetworks' "$MODELS_HYPERNETWORK_DIR"    --convert-dir
#     require_symlink 'loras'         "$MODELS_LORA_DIR"            --convert-dir
#     require_symlink 'pixart'        "$MODELS_DIR/PixArt"          --convert-dir
#     require_symlink 't5'            "$MODELS_DIR/t5"              --convert-dir
#     require_symlink 'unet'          "$MODELS_DIR/unet"            --convert-dir
#     require_symlink 'vae'           "$MODELS_VAE_DIR"             --convert-dir
#     safe_chdir "$LOCAL_DIR"
#     require_symlink 'output'        "$OUTPUT_DIR"                 --convert-dir


    #-------------------- INSTALLING ---------------------#
    safe_chdir "$LOCAL_DIR"

    ## Update PIP
    virtual_python !pip install --upgrade pip

    ## NVIDIA GPU
    virtual_python !pip install torch --index-url https://download.pytorch.org/whl/cu124
    #virtual_python !pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

    ## Dependencies
    virtual_python !pip install . --use-pep517
    #virtual_python !pip install rich semver requests plumbum prompt-toolkit
    #virtual_python !pip install -r requirements_versions.txt

    ## Building frontend
    safe_chdir "$LOCAL_DIR/invokeai/frontend/web"
    pnpm build

}


#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {

    require_venv "$VENV" "$PYTHON"

    #------------- INVOKE OPTIONS --------------#
    local options=() port_message=''
#     if [[ $PORT ]]; then
#         options+=( --port "$PORT" )
#         port_message="on port $PORT"
#     fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    message "changed working directory to $PWD"
    message "launching 'Invoke' $port_message"
    message "main.py" "${options[@]}" "$@"
    message
    export INVOKEAI_ROOT="$LOCAL_DIR"
    export PYTHONPATH="$PYTHONPATH:$LOCAL_DIR"
    virtual_python scripts/invokeai-web.py "${options[@]}" "$@"
}

