#!/usr/bin/env bash
# File    : project-forge.sh
# Brief   : Manages the local copy of the "stable diffusion webui forge" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Mar 2, 2024
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

    require_system_command git wget
    require_storage_dir

    clone_repository "$repo" "$hash" "$project_dir"
    cd "$project_dir"
    require_symlink 'outputs' "$OutputDir" --convert-dir
    virtual_python "$venv" !launch.py --no-download-sd-model --exit
}


function launch() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4
    local port_message=''

    #====== ENABLE OPTIMIZATIONS ======#
    local options=()

    # --always-gpu: ????
    #
    options+=(--always-gpu)

    # --cuda-malloc: Ask PyTorch to use cudaMallocAsync for tensor allocation.
    #                Many users have reported issues where the asynchronous allocation
    #                crashes the program. Enable this command flag at your own risk.
    #options+=(--cuda-malloc) # (has not shown a significant speed increase)

    # --cuda-stream: Use PyTorch CUDA streams to move models and compute tensors simultaneously.
    #                Unfortunately, this can lead to the generation of pure
    #                black images. Enable this command flag at your own risk.
    #options+=(--cuda-stream) # (has not shown a significant speed increase)

    # --pin-shared-memory: Offload modules to Shared GPU Memory instead of system RAM.
    #                      Very risky because running out of shared GPU memory is a
    #                      severe problem. Enable this command flag at your own risk.
    #options+=(--pin-shared-memory) # (has not shown a significant speed increase)

    #options+=(--xformers)                  # possibly no longer necessary with Torch 2
    #options+=(--opt-sdp-attention)         # non-deterministic, can be faster but uses more VRAM than xFormers
    #options+=(--opt-sdp-no-mem-attention)  # deterministic, can be faster but uses more VRAM than xFormers


    #====== CONFIGURE USER SETTINGS ======#
    options+=( --theme dark ) # start in dark mode
    options+=( --listen     ) # disable browser launch and allows connection from LAN
    if [[ $ProjectPort ]]; then
        options+=( --port $ProjectPort )
        port_message="on port $ProjectPort"
    fi
    #options+=(--autolaunch) # force browser launch even when --listen is enabled


    #====== REDIRECT DIRECTORIES FOR AIMAN ======#
    local directories=()
    directories+=( --codeformer-models-path "$ModelsCodeformerDir"      )
    directories+=( --embeddings-dir         "$ModelsEmbeddingsDir"      )
    directories+=( --esrgan-models-path     "$ModelsEsrganDir"          )
    directories+=( --gfpgan-models-path     "$ModelsGfpganDir"          )
    directories+=( --hypernetwork-dir       "$ModelsHypernetworkDir"    )
    directories+=( --ldsr-models-path       "$ModelsLdsrDir"            )
    directories+=( --lora-dir               "$ModelsLoraDir"            )
    directories+=( --realesrgan-models-path "$ModelsRealesrganDir"      )
    directories+=( --scunet-models-path     "$ModelsScunetDir"          )
    directories+=( --ckpt-dir               "$ModelsStableDiffusionDir" )
    directories+=( --swinir-models-path     "$ModelsSwinirDir"          )
    directories+=( --vae-dir                "$ModelsVaeDir"             )

    cd "$project_dir"
    echox check "changed working directory to $PWD"
    echox wait  "launching SD WebUI Forge application $port_message"
    virtual_python "$venv" !launch.py "${options[@]}" "${directories[@]}" "$@"
}


# function update() {
#     git pull
# }
# function revert() {
#     local hash=$(print_project @hash)
#     if [[ -n "$hash" ]]; then
#         git reset --hard "$hash"
#     fi
# }

