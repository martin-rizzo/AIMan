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
#   - ProjectName : the short name of the project, e.g. "webui"
#   - ProjectPort : the port where the app should listen, empty = default
#
function install() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    require_system_command git
    require_storage_dir

    clone_repository "$repo" "$hash" "$project_dir"
    cd "$project_dir/models"
    require_symlink 'checkpoints' "$ModelsStableDiffusionDir" --convert-dir
    require_symlink 'controlnet'  "$ModelsControlnetDir"      --convert-dir
    require_symlink 'embeddings'  "$ModelsEmbeddingsDir"      --convert-dir
    require_symlink 'hypernetworks' "$ModelsHypernetworkDir"  --convert-dir
    require_symlink 'loras'       "$ModelsLoraDir"            --convert-dir
    require_symlink 't5'          "$ModelsDir/t5"             --convert-dir
    require_symlink 'vae'         "$ModelsVaeDir"             --convert-dir
    cd "$project_dir"
    require_symlink 'output'      "$OutputDir"                --convert-dir

    #--------------- INSTALLING ----------------#
    cd "$project_dir"

    ## NVIDIA GPU
    virtual_python "$venv" !pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121

    ## Dependencies
    virtual_python "$venv" !pip install -r requirements.txt
    #virtual_python "$venv" !pip install accelerate

    #------------ ADD CUSTOM NODES -------------#
    cd "$project_dir/custom_nodes"

    ## Advanced CLIP Text Encode
    # nodes that allows for more control over the way prompt weighting should be interpreted
    git clone https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb

    ## ComfyUI Noise
    # nodes that allows for more control and flexibility over noise to do
    git clone https://github.com/BlenderNeko/ComfyUI_Noise

    ## Extra Models for ComfyUI
    # support miscellaneous image models: DiT, PixArt, T5 and a few custom VAEs
    git clone https://github.com/city96/ComfyUI_ExtraModels
    virtual_python "$venv" !pip install -r ComfyUI_ExtraModels/requirements.txt
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
#   - ProjectName : the short name of the project, e.g. "webui"
#   - ProjectPort : the port where the app should listen, empty = default
#
function launch() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4
    local port_message=''

    #------------- COMFYUI OPTIONS -------------#
    local options=()
    if [[ $ProjectPort ]]; then
        options+=( --port $ProjectPort )
        port_message="on port $ProjectPort"
    fi

    #---------------- LAUNCHING ----------------#
    cd "$project_dir"
    echox check "changed working directory to $PWD"
    echox wait  "launching ComfyUI application $port_message"
    virtual_python "$venv" main.py "${options[@]}" "$@"
}

