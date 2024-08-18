#!/usr/bin/env bash
# File    : project-webui.sh
# Brief   : Manages the local copy of the "stable diffusion webui" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 6, 2023
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
    local config_file="$project_dir/config.json"

    require_system_command git wget
    require_storage_dir
    require_venv "$venv"

    echox wait "cloning repository"
    clone_repository "$repo" "$hash" "$project_dir"
    safe_chdir "$project_dir"
    require_symlink 'outputs'    "$OUTPUT_DIR"                  --convert-dir
    require_symlink 'styles.csv' "$MODELS_STYLES_DIR/styles.csv" --move-file

    #--------------- EXTENSIONS ----------------#
    safe_chdir "$project_dir/extensions"
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
    safe_chdir "$project_dir"
    echox wait "installing 'Stable Diffusion WebUI'"
    virtual_python launch.py --no-download-sd-model --exit
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
    local port_message=''

    require_venv "$venv"

    #--------- CONFIGURE USER SETTINGS ---------#
    local options=()
    options+=( --theme dark  )   # start in dark mode

    # listering in the custom port
    if [[ $PROJECT_PORT ]]; then
        options+=( --port $PROJECT_PORT )
        port_message="on port $PROJECT_PORT"
    fi

    #-------------- OPTIMIZATIONS --------------#
    local optimizations=()
    optimizations+=( --opt-sdp-attention        ) # non-deterministic, can be faster but uses more VRAM than xFormers
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

    safe_chdir "$project_dir"
    echox check "changed working directory to $PWD"
    echox wait  "launching AUTO1111 WebUI application $port_message"
    virtual_python launch.py "${options[@]}" "${optimizations[@]}" "${directories[@]}" "$@"
}

