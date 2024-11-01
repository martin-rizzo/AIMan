#!/usr/bin/env bash
# File    : handlers/comfyui.sh
# Brief   : Manages the local copy of "ComfyUI".
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Nov 28, 2023
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
    PORT=$2
    VENV=$3
    PYTHON=python3.12 # =$4
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

    require_system_command git "$PYTHON"
    require_storage_dir
    require_venv "$VENV" "$PYTHON"

    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR/models"
    require_symlink 'checkpoints'   "$MODELS_STABLEDIFFUSION_DIR" --convert-dir
    require_symlink 'clip'          "$MODELS_TEXTENCODER_DIR"     --convert-dir
    require_symlink 'controlnet'    "$MODELS_CONTROLNET_DIR"      --convert-dir
    require_symlink 'embeddings'    "$MODELS_EMBEDDINGS_DIR"      --convert-dir
    require_symlink 'hypernetworks' "$MODELS_HYPERNETWORK_DIR"    --convert-dir
    require_symlink 'loras'         "$MODELS_LORA_DIR"            --convert-dir
    require_symlink 'pixart'        "$MODELS_DIR/PixArt"          --convert-dir
    require_symlink 't5'            "$MODELS_DIR/t5"              --convert-dir
    require_symlink 'unet'          "$MODELS_DIR/unet"            --convert-dir
    require_symlink 'vae'           "$MODELS_VAE_DIR"             --convert-dir
    safe_chdir "$LOCAL_DIR"
    require_symlink 'output'        "$OUTPUT_DIR"                 --convert-dir



    #-------------------- INSTALLING ---------------------#

    safe_chdir "$LOCAL_DIR"

    ## Update PIP & pyyaml
    virtual_python !pip install --upgrade pip
    virtual_python !pip install pyyaml

    ## NVIDIA GPU + pytorch 2.5.0 + CUDA 12.4
    virtual_python !pip install torch torchvision torchaudio

    ## Dependencies
    virtual_python !pip install -r requirements.txt
   #virtual_python !pip install bitsandbytes
   #virtual_python !pip install accelerate

    #----------------- ADD CUSTOM NODES ------------------#

    safe_chdir "$LOCAL_DIR/custom_nodes"

    ## ComfyUI Manager
    # management functions to install, remove, disable, and enable custom nodes
    git clone https://github.com/ltdrdata/ComfyUI-Manager
    virtual_python !pip install -r ComfyUI-Manager/requirements.txt

    ## Crystools
    # a powerful set of tools, include performance graphs below the queue prompt
    git clone https://github.com/crystian/ComfyUI-Crystools
    virtual_python !pip install -r ComfyUI-Crystools/requirements.txt

    ## Extra Models
    # support miscellaneous image models: DiT, PixArt, T5 and a few custom VAEs
    git clone https://github.com/city96/ComfyUI_ExtraModels
    virtual_python !pip install -r ComfyUI_ExtraModels/requirements.txt

    ### ComfyUI GGUF
    ## GGUF Quantization support for native ComfyUI models
    #git clone https://github.com/city96/ComfyUI-GGUF
    #virtual_python !pip install -r ComfyUI-GGUF/requirements.txt

    ### Comfyroll Studio
    ## many util nodes including prompt nodes, pipe nodes, text nodes, logic nodes, ...
    #git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes

    ## Advanced CLIP Text Encode
    # nodes that allows for more control over the way prompt weighting should be interpreted
    #git clone https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb

    ## ComfyUI Noise
    # nodes that allows for more control and flexibility over noise to do
    #git clone https://github.com/BlenderNeko/ComfyUI_Noise

    ## ComfyUI Inspire Pack [Error: No module named 'cv2']
    # powerful set of tools providing nodes for enhancing the functionality of ComfyUI
    #git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack
    #virtual_python !pip install -r ComfyUI-Inspire-Pack/requirements.txt

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

    #------------- COMFYUI OPTIONS -------------#
    local options=() port_message=''
    if [[ $PORT ]]; then
        options+=( --port "$PORT" )
        port_message="on port $PORT"
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    message "changed working directory to $PWD"
    message "launching ComfyUI application $port_message"
    message "main.py" "${options[@]}" "$@"
    message
    virtual_python main.py "${options[@]}" "$@"
}
