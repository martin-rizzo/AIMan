#!/usr/bin/env bash
# File    : project-comfyui.sh
# Brief   : Manages the local copy of the "comfyui" project.
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

    require_system_command git
    require_storage_dir
    require_venv "$venv"

    clone_repository "$repo" "$hash" "$project_dir"
    safe_chdir "$project_dir/models"
    require_symlink 'checkpoints'   "$MODELS_STABLEDIFFUSION_DIR" --convert-dir
    require_symlink 'controlnet'    "$MODELS_CONTROLNET_DIR"      --convert-dir
    require_symlink 'embeddings'    "$MODELS_EMBEDDINGS_DIR"      --convert-dir
    require_symlink 'hypernetworks' "$MODELS_HYPERNETWORK_DIR"    --convert-dir
    require_symlink 'loras'         "$MODELS_LORA_DIR"            --convert-dir
    require_symlink 'pixart'        "$MODELS_DIR/PixArt"         --convert-dir
    require_symlink 't5'            "$MODELS_DIR/t5"             --convert-dir
    require_symlink 'vae'           "$MODELS_VAE_DIR"             --convert-dir
    safe_chdir "$project_dir"
    require_symlink 'output'        "$OUTPUT_DIR"                --convert-dir



    #-------------------- INSTALLING ---------------------#

    safe_chdir "$project_dir"

    ## Update PIP
    virtual_python !pip install --upgrade pip

    ## NVIDIA GPU
    virtual_python !pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

    ## Dependencies
    virtual_python !pip install -r requirements.txt
    virtual_python !pip install bitsandbytes
   #virtual_python !pip install accelerate

    #----------------- ADD CUSTOM NODES ------------------#

    safe_chdir "$project_dir/custom_nodes"

    ## ComfyUI Manager
    # management functions to install, remove, disable, and enable custom nodes
    git clone https://github.com/ltdrdata/ComfyUI-Manager
    virtual_python !pip install -r ComfyUI-Manager/requirements.txt

    ## Crystools
    # a powerful set of tools, include performance graphs below the queue prompt
    git clone https://github.com/crystian/ComfyUI-Crystools
    virtual_python !pip install -r ComfyUI-Crystools/requirements.txt

    ## Comfyroll Studio
    # many util nodes including prompt nodes, pipe nodes, text nodes, logic nodes, ...
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes

    ## Extra Models
    # support miscellaneous image models: DiT, PixArt, T5 and a few custom VAEs
    git clone https://github.com/city96/ComfyUI_ExtraModels
    virtual_python !pip install -r ComfyUI_ExtraModels/requirements.txt

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

    require_venv "$venv"

    #------------- COMFYUI OPTIONS -------------#
    local options=() port_message=''
    if [[ $PROJECT_PORT ]]; then
        options+=( --port "$PROJECT_PORT" )
        port_message="on port $PROJECT_PORT"
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$project_dir"
    message "changed working directory to $PWD"
    message "launching ComfyUI application $port_message"
    virtual_python main.py "${options[@]}" "$@"
}
