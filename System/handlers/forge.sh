#!/usr/bin/env bash
# File    : handlers/forge.sh
# Brief   : Manages the local copy of "Stable Diffusion WebUI Forge".
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

AUTO_LAUNCH_BROWSER='Disable' # Automatically open webui in browser on startup (Disable/Local/Remote)
EXPORT_FOR_4CHAN='false'      # Save copy of large images as JPG (true/false)

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
    PYTHON=python3.10 # =$4
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
    local config_file="$LOCAL_DIR/config.json"

    require_system_command git wget
    require_storage_dir
    require_venv "$VENV" "$PYTHON"

    clone_repository "$REMOTE_URL" "$REMOTE_HASH" "$LOCAL_DIR"
    safe_chdir "$LOCAL_DIR"
    require_symlink 'outputs'    "$OUTPUT_DIR"                  --convert-dir
    require_symlink 'styles.csv' "$MODELS_STYLES_DIR/styles.csv" --move-file

    #--------------- EXTENSIONS ----------------#
    safe_chdir "$LOCAL_DIR/extensions"
    echox wait "installing 'One Button Prompt' extension"
    git clone https://github.com/AIrjen/OneButtonPrompt > /dev/null
    echox wait "installing 'Test my prompt!' extension"
    git clone https://github.com/Extraltodeus/test_my_prompt > /dev/null
    echox wait "installing 'Incantations' extension"
    git clone https://github.com/v0xie/sd-webui-incantations.git > /dev/null

    #---------- DEFAULT CONFIGURATION ----------#
    echox wait "generating default configuration"
    echo "
    {
         \"auto_launch_browser\": \"$AUTO_LAUNCH_BROWSER\",
         \"export_for_4chan\": $EXPORT_FOR_4CHAN
    }
    " > "$config_file"
    echo "$config_file"

    #--------------- INSTALLING ----------------#
    safe_chdir "$LOCAL_DIR"
    echox wait "installing 'Stable Diffusion FORGE'"
    virtual_python launch.py --no-download-sd-model --exit
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

    #--------- CONFIGURE USER SETTINGS ---------#
    local options=() port_message=''
    options+=( --theme dark  )   # start in dark mode

    # listering in the custom port
    if [[ $PORT ]]; then
        options+=( --port "$PORT" )
        port_message="on port $PORT"
    fi

    #-------------- OPTIMIZATIONS --------------#
    local optimizations=()

    # --always-gpu: ????
    #
    optimizations+=( --always-gpu )

    # --cuda-malloc: Ask PyTorch to use cudaMallocAsync for tensor allocation.
    #                Many users have reported issues where the asynchronous allocation
    #                crashes the program. Enable this command flag at your own risk.
    #optimizations+=( --cuda-malloc ) # -has not shown a significant speed increase-

    # --cuda-stream: Use PyTorch CUDA streams to move models and compute tensors simultaneously.
    #                Unfortunately, this can lead to the generation of pure
    #                black images. Enable this command flag at your own risk.
    #optimizations+=( --cuda-stream ) # -has not shown a significant speed increase-

    # --pin-shared-memory: Offload modules to Shared GPU Memory instead of system RAM.
    #                      Very risky because running out of shared GPU memory is a
    #                      severe problem. Enable this command flag at your own risk.
    #optimizations+=( --pin-shared-memory ) # -has not shown a significant speed increase-

    #optimizations+=( --opt-sdp-attention        ) # non-deterministic, can be faster but uses more VRAM than xFormers
    #optimizations+=( --opt-sdp-no-mem-attention ) # deterministic, can be faster but uses more VRAM than xFormers
    #optimizations+=( --xformers                 ) # possibly no longer necessary with Torch 2

    #------ REDIRECT DIRECTORIES TO AIMAN ------#
    local directories=()
    directories+=( --codeformer-models-path "$MODELS_CODEFORMER_DIR"      )
    directories+=( --embeddings-dir         "$MODELS_EMBEDDINGS_DIR"      )
    directories+=( --esrgan-models-path     "$MODELS_ESRGAN_DIR"          )
    directories+=( --gfpgan-models-path     "$MODELS_GFPGAN_DIR"          )
    directories+=( --hypernetwork-dir       "$MODELS_HYPERNETWORK_DIR"    )
    directories+=( --ldsr-models-path       "$MODELS_LDSR_DIR"            )
    directories+=( --lora-dir               "$MODELS_LORA_DIR"            )
    directories+=( --realesrgan-models-path "$MODELS_REALESRGAN_DIR"      )
    directories+=( --scunet-models-path     "$MODELS_SCUNET_DIR"          )
    directories+=( --ckpt-dir               "$MODELS_STABLEDIFFUSION_DIR" )
    directories+=( --swinir-models-path     "$MODELS_SWINIR_DIR"          )
    directories+=( --vae-dir                "$MODELS_VAE_DIR"             )

    safe_chdir "$LOCAL_DIR"
    echox check "changed working directory to $PWD"
    echox wait  "launching SD WebUI Forge application $port_message"
    virtual_python launch.py "${options[@]}" "${optimizations[@]}" "${directories[@]}" "$@"
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

