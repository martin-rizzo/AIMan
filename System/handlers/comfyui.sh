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
    SHARED_TMP_DIR=$8  #< temporary directory shared with other apps and users
    
    # ensure the shared folder exists
    [[ -d "$SHARED_TMP_DIR" ]] || \
        bug_report "init parameter 8: '$SHARED_TMP_DIR' is not a valid directory"

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
# The AIMAN environment invokes the functions in the following order:
#     _init_ ...
#     cmd_launch [user_args]
#
# This function implements a robust launch mechanism for ComfyUI that:
#  - Sets up environment variables and options
#  - Manages process lifecycle with restart and quit controls
#  - Handles keyboard input for user interaction
#  - Supports external IPC triggers via named pipe
#  - Cleans up resources on exit
#
cmd_launch() {
    require_venv "$VENV" "$PYTHON"

    # set the specific Chrome Extension ID authorized to launch ComfyUI (e.g., Speed Dial)
    # this avoids "403 Forbidden" and ensures only this ID has CORS permission.
    # you can set COMFYUI_ALLOWED_CHROME_EXT_ID in your .bashrc or environment.
    local COMFYUI_ALLOWED_CHROME_EXT_ID="${COMFYUI_ALLOWED_CHROME_EXT_ID:-${YET_ANOTHER_SPEED_DIAL_EXT_ID}}"

    # pipe file to control restarting/quitting
    # the pipe must be in a shared directory
    # so that any user/process can access it
    local PIPE_FILE="$SHARED_TMP_DIR/comfyui_trigger"

    
    #------------- COMFYUI OPTIONS -------------#
    local options=()
    local launching_extra_message=""
    
    # Enable high-quality Latent previews during generation
    options+=( --preview-method auto )
    
    # Set custom network port if required
    if [[ -n "$PORT" ]]; then
        options+=( --port "$PORT" )
        launching_extra_message="on port $PORT"
    fi
    
    # enable CORS header for allowed Chrome Extension
    # (this enables the chrome extension to launch ComfyUI)
    if [[ -n "$COMFYUI_ALLOWED_CHROME_EXT_ID" ]]; then
        options+=( --enable-cors-header "chrome-extension://$COMFYUI_ALLOWED_CHROME_EXT_ID" )
    fi
    
    # restrict listener to localhost to prevent external network access
    options+=( --listen 127.0.0.1 )
    
    
    #---------------- LAUNCHING ----------------#
    safe_chdir "$LOCAL_DIR"
    message "changed working directory to $PWD"
    
    # create the named pipe and set open permissions
    rm -f "$PIPE_FILE"
    mkfifo "$PIPE_FILE"
    chmod 666 "$PIPE_FILE"
    
    # clean up files and process on exit
    # shellcheck disable=SC2329
    cleanup_on_exit() {
        rm -f "$PIPE_FILE"
        [[ -n "$COMFYUI_PID" ]] && kill "$COMFYUI_PID" 2>/dev/null
    }
    trap cleanup_on_exit SIGINT EXIT
    
    while true; do
        local key='' cmd=''
        
        # Launch ComfyUI as a background job
        message "launching ComfyUI application ${launching_extra_message}"
        message         'main.py' "${options[@]}" "$@"
        virtual_python '&main.py' "${options[@]}" "$@"
        COMFYUI_PID=$!
        message "comfyUI launched with PID: $COMFYUI_PID"
        
        # print banner explaining all controls
        echo
        echo -e "${MAGENTA}╭─────────────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${MAGENTA}│${RESET} ${CYAN}⚙️  COMFYUI CONTROL PANEL${RESET}                                        ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}├─────────────────────────────────────────────────────────────────┤${RESET}"
        echo -e "${MAGENTA}│${RESET} ${GREEN}[r]${RESET} ${BOLD}Keyboard:${RESET} Restart ComfyUI immediately                       ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET} ${RED}[q]${RESET} ${BOLD}Keyboard:${RESET} Shut down and exit completely                     ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET} ${YELLOW}[IPC Trigger]${RESET} From another user/project run:                    ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}                                                                 ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}   echo \"restart\" > ${PIPE_FILE}${RESET}               ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}│${RESET}                                                                 ${MAGENTA}│${RESET}"
        echo -e "${MAGENTA}╰─────────────────────────────────────────────────────────────────╯${RESET}\n"
        
        while kill -0 "$COMFYUI_PID" 2>/dev/null; do

            # check the pipe for external commands (100ms timeout)
            if [[ -p "$PIPE_FILE" ]]; then
                read -t 0.1 -r cmd <> "$PIPE_FILE" 2>/dev/null
            fi
            
            # check keyboard input (100ms timeout)
            read -t 0.1 -n 1 -r key 2>/dev/null
            [[ $key == "r" ]] && cmd="restart"
            [[ $key == "q" ]] && cmd="quit"
            
            if [[ "$cmd" == "quit" || "$cmd" == "restart" ]]; then
                kill "$COMFYUI_PID" 2>/dev/null
                break
            fi
            
            # small sleep to prevent CPU spiking
            sleep 1

        done
        
        # wait as max 5 seconds to normally finish ComfyUI
        # and then kill any process of ComfyUI that may be stuck
        timeout 5s wait "$COMFYUI_PID" 2>/dev/null
        echo
        if [[ $cmd == "quit" ]]; then
            echo -e "Shutting down..."
            return 0
        fi

    done
}