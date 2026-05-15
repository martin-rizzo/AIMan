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

# The launcher extension that I use in chrome:
# https://chromewebstore.google.com/detail/yet-another-speed-dial/imohnlganmafcmidafklgkgfgaagiohn
YET_ANOTHER_SPEED_DIAL_EXT_ID=imohnlganmafcmidafklgkgfgaagiohn


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
    NAME=$1
    PORT=$2
    VENV=$3
    PYTHON=$4
    LOCAL_DIR=$5
    REMOTE_URL=$6
    REMOTE_HASH=$7

    case "$NAME" in
        'comfyui')
            PYTHON="python3.13"
            TORCH="2.10"
            ;;
        'comfystable')
            PYTHON="python3.10"
            TORCH="2.5"
            ;;
        *)
            echo "Error: Invalid name parameter. Please specify either 'comfystable' or 'comfyui'."
            exit 1
            ;;
    esac
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
    require_symlink 'checkpoints'      "$MODELS_STABLEDIFFUSION_DIR"  --convert-dir
    require_symlink 'controlnet'       "$MODELS_CONTROLNET_DIR"       --convert-dir
    require_symlink 'diffusion_models' "$MODELS_DIR/diffusion_models" --convert-dir
    require_symlink 'embeddings'       "$MODELS_EMBEDDINGS_DIR"       --convert-dir
    require_symlink 'hypernetworks'    "$MODELS_HYPERNETWORK_DIR"     --convert-dir
    require_symlink 'loras'            "$MODELS_LORA_DIR"             --convert-dir
    require_symlink 'text_encoders'    "$MODELS_TEXTENCODER_DIR"      --convert-dir
    require_symlink 'unet'             "$MODELS_DIR/unet"             --convert-dir
    require_symlink 'upscale_models'   "$MODELS_DIR/ESRGAN"           --convert-dir
    require_symlink 'vae'              "$MODELS_VAE_DIR"              --convert-dir
    require_symlink 'vae_approx'       "$MODELS_VAE_APPROX_DIR"       --convert-dir
    safe_chdir "$LOCAL_DIR"
    require_symlink 'output' "$OUTPUT_DIR" --convert-dir

    #-------------------- INSTALLING ---------------------#

    safe_chdir "$LOCAL_DIR"

    ## Update PIP & pyyaml
    virtual_python !pip install --upgrade pip
    virtual_python !pip install pyyaml

    ## pytorch 2.3.1 using CUDA 11.8 (NVIDIA GPU)
    if [[ $TORCH == '2.3' ]]; then
        virtual_python !pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu118
    fi

    ## pytorch 2.4.1 using CUDA 12.1 (NVIDIA GPU)
    if [[ $TORCH == '2.4' ]]; then
        virtual_python !pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu121
    fi

    ## pytorch 2.5.1 using CUDA 12.4 (NVIDIA GPU)
    if [[ $TORCH == '2.5' ]]; then
        virtual_python !pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124
    fi

    ## pytorch 2.7.1 using CUDA 12.6 (NVIDIA GPU)
    if [[ $TORCH == '2.7' ]]; then
        virtual_python !pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu126
    fi

    ## pytorch 2.9.1 using CUDA 12.8 (NVIDIA GPU)
    if [[ $TORCH == '2.9' ]]; then
        virtual_python !pip install torch==2.9.1 torchvision==0.24.1 torchaudio==2.9.1 --index-url https://download.pytorch.org/whl/cu128
    fi

    ## pytorch 2.10.0 using CUDA 13.0 (NVIDIA GPU)
    if [[ $TORCH == '2.10' ]]; then
        virtual_python !pip install torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu130
    fi

    # ## pytorch 2.10.0 using CUDA 13.0 (NVIDIA GPU)
    # if [[ $TORCH == 'last' ]]; then
    #     virtual_python !pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130
    # fi

    ## Dependencies
    virtual_python !pip install -r requirements.txt
   #virtual_python !pip install bitsandbytes
   #virtual_python !pip install accelerate

    #----------------- ADD CUSTOM NODES ------------------#
    safe_chdir "$LOCAL_DIR/custom_nodes"

    # ask for user confirmation if they want to install "ComfyUI Manager"
    if ask_confirmation \
        "Would you like to install ComfyUI-Manager?" \
        "ComfyUI-Manager allows you to install, remove, disable, and enable various custom nodes of ComfyUI."
    then
        git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
        virtual_python !pip install -r ComfyUI-Manager/requirements.txt
    fi

    # ask for user confirmation if they want to install nodes for GGUF support
    if ask_confirmation \
        "Would you like to install ComfyUI-GGUF?" \
        "ComfyUI-GGUF allows you to load checkpoints in GGUF format."
    then
        git clone https://github.com/city96/ComfyUI-GGUF.git
        virtual_python !pip install -r ComfyUI-GGUF/requirements.txt
    fi

    ## Crystools
    # A powerful set of tools, include performance graphs below the queue prompt
    #git clone https://github.com/crystian/ComfyUI-Crystools
    #virtual_python !pip install -r ComfyUI-Crystools/requirements.txt

    ## Extra Models
    # Support miscellaneous image models: DiT, PixArt, T5 and a few custom VAEs
    #git clone https://github.com/city96/ComfyUI_ExtraModels
    #virtual_python !pip install -r ComfyUI_ExtraModels/requirements.txt

    ## OmniGen-ComfyUI
    # A custom node for OmniGen [https://github.com/VectorSpaceLab/OmniGen]
    #git clone https://github.com/AIFSH/OmniGen-ComfyUI
    #git clone https://github.com/harkonkr/OmniGen-ComfyUI
    #virtual_python !pip install -r OmniGen-ComfyUI/requirements.txt

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

COMFYUI_PID=

#============================================================================
# Launches the project application in the specified environment.
#
# Usage:
#   _init_ ...
#   cmd_launch [user_args]
#
cmd_launch() {

    require_venv "$VENV" "$PYTHON"
    local launching_message="launching ComfyUI application"

    # set the specific Chrome Extension ID authorized to access ComfyUI (e.g., Speed Dial)
    # this avoids "403 Forbidden" and ensures only this ID has CORS permission.
    # you can set COMFYUI_ALLOWED_CHROME_EXT_ID in your .bashrc or environment.
    local COMFYUI_ALLOWED_CHROME_EXT_ID="${COMFYUI_ALLOWED_CHROME_EXT_ID:-${YET_ANOTHER_SPEED_DIAL_EXT_ID}}"


    #------------- COMFYUI OPTIONS -------------#
    local options=()

    # enable high-quality Latent previews during the generation process
    # set the method to display image previews during generation.
    # available options:
    #   - auto      : automatically selects the best available method.
    #   - latent2rgb: fast, low-resolution preview (very lightweight).
    #   - taesd     : high-quality preview using Tiny AutoEncoder (requires TAESD models).
    #   - none      : disables previews entirely to save resources.
    options+=( --preview-method auto )

    # set custom network port if required
    if [[ $PORT ]]; then
        options+=( --port "$PORT" )
        launching_message="launching ComfyUI application on port $PORT"
    fi

    # enable CORS header for Chrome Extensions
    if [[ -n "$COMFYUI_ALLOWED_CHROME_EXT_ID" ]]; then
        options+=( --enable-cors-header "chrome-extension://$COMFYUI_ALLOWED_CHROME_EXT_ID" )
    fi


    # restrict listener to localhost to prevent external network access
    # (safer than --listen)
    options+=( --listen 127.0.0.1 )

    # bypass "403 Forbidden" errors when calling from chrome extensions (e.g Speed Dial)
    # Replace 'YOUR_EXTENSION_ID' with the ID found in chrome://extensions
    # if the ID is unknown, you can use '*' temporarily, but more dangerous
    # asi que mejor specific ID is recommended.
    local ext_id="YOUR_EXTENSION_ID_HERE"
    ext_id="imohnlganmafcmidafklgkgfgaagiohn"

    if [[ $ext_id != 'YOUR_EXTENSION_ID_HERE' ]]; then
        options+=( --enable-cors-header "chrome-extension://$ext_id" )
    fi

    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    message "changed working directory to $PWD"
    message "$launching_message"
    message "main.py" "${options[@]}" "$@"
    message

    # when this script receives a SIGINT (Ctrl+C),
    # it will terminate the comfyui processes
    trap '[[ -n "$COMFYUI_PID" ]] && kill "$COMFYUI_PID"' SIGINT

    while true; do
        local key='' restart=''

        # launch ComfyUI as a background job to be able to monitor the keyboard
        virtual_python '&main.py' "${options[@]}" "$@"
        COMFYUI_PID=$!
        message "comfyUI launched with PID: $COMFYUI_PID"

        # loop while comfyui is running
        echo ">>>> Press 'r' to restart, 'q' to quit."
        while kill -0 "$COMFYUI_PID" 2>/dev/null; do
            read -t 1 -n 1 -r key # read 1 character (-n1) with a 1-second timeout (-t1)

            if [[ $key == "r" ]]; then
                restart=true
                echo -e "\nRestarting ComfyUI..."
                kill "$COMFYUI_PID"
            fi

            if [[ $key == "q" ]]; then
                echo -e "\nShutting down..."
                kill "$COMFYUI_PID"
            fi

        done

        # wait for comfyui process to finish
        # and exit if a restart was not requested
        wait "$COMFYUI_PID" 2>/dev/null
        [[ ! $restart ]] && exit 0
    done

}

