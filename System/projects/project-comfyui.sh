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


function install() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    require_system_command git
    require_storage_dir

    clone_repository "$repo" "$hash" "$project_dir"
    cd "$project_dir"
    require_symlink 'models/checkpoints' "$ModelsStableDiffusionDir" --convert-dir
    require_symlink 'models/vae'         "$ModelsVaeDir"             --convert-dir
    require_symlink 'models/loras'       "$ModelsLoraDir"            --convert-dir
    require_symlink 'models/controlnet'  "$ModelsControlnetDir"      --convert-dir
    require_symlink 'output'             "$OutputDir"                --convert-dir

    #--- custom nodes ----
    cd "$project_dir/custom_nodes"

    # Advanced CLIP Text Encode
    # nodes that allows for more control over the way prompt weighting should be interpreted
    git clone https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb.git

    # ComfyUI Noise
    # nodes that allows for more control and flexibility over noise to do
    git clone https://github.com/BlenderNeko/ComfyUI_Noise.git

    cd ..
    #-----------------------

    ## NVIDIA GPU
    virtual_python "$venv" pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121

    ## Dependencies
    virtual_python "$venv" pip install -r requirements.txt
}


function launch() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    cd "$project_dir"
    virtual_python "$venv" !main.py "$@"
}

