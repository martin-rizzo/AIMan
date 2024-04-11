#!/usr/bin/env bash
# File    : project-comfyui.sh
# Brief   : Controls the local copy of the "comfyui" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Nov 28, 2023
# Repo    : https://github.com/martin-rizzo/AIMan
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                    AIMan
#        A basic package management system for AI open source projects
#   
#     Copyright (c) 2023 Martin Rizzo
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
    local project_dir=$(print_project @local_dir)

    require_system_command git
    require_virtual_python
    
    change_to_repo_directory
    clone_project_to "$project_dir"
    cd "$project_dir"
    require_soft_link 'models/checkpoints' '../../../Models/Stable-diffusion' 1
    require_soft_link 'models/vae'         '../../../Models/VAE'              1
    require_soft_link 'models/loras'       '../../../Models/Lora'             1
    require_soft_link 'models/controlnet'  '../../../Models/ControlNet'       1
    require_soft_link 'output'             '../../Output'                     1
    # export INVOKEAI_ROOT=$project_dir
    
    #--- custom nodes ----
    cd custom_nodes
    
    # Advanced CLIP Text Encode
    # nodes that allows for more control over the way prompt weighting should be interpreted
    git clone https://github.com/BlenderNeko/ComfyUI_ADV_CLIP_emb.git
    
    # ComfyUI Noise
    # nodes that allows for more control and flexibility over noise to do
    git clone https://github.com/BlenderNeko/ComfyUI_Noise.git
    
    cd ..
    #-----------------------

    # NVIDIA GPU
    virtual_python !pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
    
    # Dependencies
    virtual_python !pip install -r requirements.txt
    
}

function launch() {
    local project_dir=$(print_project @local_dir)
    local options=("$@")

    change_to_repo_directory
    cd "$project_dir"
    virtual_python main.py "${options[@]}"
}
