#!/usr/bin/env bash
# File    : project-webui.sh
# Brief   : Controls the local copy of the "stable diffusion webui" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 6, 2023
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
    local project_dir=$(print_project @directory)
    
    require_system_command git wget
    require_virtual_python
    
    change_to_repo_directory
    clone_project_to "$project_dir"
    cd "$project_dir"
    virtual_python launch.py --no-download-sd-model --exit    
}

function launch() {
    local project_dir=$(print_project @directory)
    local options=("$@")
    local directories=()
    
    options+=(--xformers)
    options+=(--theme dark)
   #options+=(--autolaunch)
    
    directories+=(--codeformer-models-path "$ModelsCodeformerDir")
    directories+=(--embeddings-dir "$ModelsEmbeddingsDir")
    directories+=(--esrgan-models-path "$ModelsEsrganDir")
    directories+=(--gfpgan-models-path "$ModelsGfpganDir")
    directories+=(--hypernetwork-dir "$ModelsHypernetworkDir")
    directories+=(--ldsr-models-path "$ModelsLdsrDir")
    directories+=(--lora-dir "$ModelsLoraDir")
    directories+=(--realesrgan-models-path "$ModelsRealesrganDir")
    directories+=(--scunet-models-path "$ModelsScunetDir")
    directories+=(--ckpt-dir "$ModelsStableDiffusionDir")
    directories+=(--swinir-models-path "$ModelsSwinirDir")
    directories+=(--vae-dir "$ModelsVaeDir")
    
    change_to_repo_directory
    cd "$project_dir"
    virtual_python launch.py "${options[@]}" "${directories[@]}"
}

function update() {
    git pull
}

function revert() {
    local hash=$(print_project @hash)
    if [[ -n "$hash" ]]; then
        git reset --hard "$hash"
    fi
}

