#!/usr/bin/env bash
#shellcheck disable=SC2034 # disable warning for unused variables, as they are used in other scripts.
# File    : aiman
# Brief   : Main script
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
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
AIMAN=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$AIMAN")
SCRIPT_NAME=$(basename "$AIMAN")
SCRIPT_VER=0.1      # script version
PROJECT_NAME=       # name of the project on which the command will be executed
COMMAND_NAME=       # name of the command to be executed
COMMAND_PARAMS=()   # parameters for the command
HELP="
Usage: $SCRIPT_NAME [PROJECT.]COMMAND [param1] [param2] ... [paramN]

  A command-line package manager for AI open source projects.

Commands:
    install    Install projects on the local directory.
    launch     Launch projects that have been previously installed.
    remove     Remove installed projects.
    list       List all available projects.
    info       Display details about the project.
    venv       Display environment info and library versions for the project.
    console    Execute commands within the python virtual environment.
    setdir     Change the directories used for input and output.
    add2path   Add aiman to the user's PATH.

Run '$SCRIPT_NAME COMMAND --help' for more information on a command.

Options:
    -h, --help      Show command help
    -V, --version   Show $SCRIPT_NAME version and exit

Examples:
    $SCRIPT_NAME list
    $SCRIPT_NAME webui.info
    $SCRIPT_NAME webui.console pip upgrade
    $SCRIPT_NAME launch --help
"

# Define directory paths relative to the base directory
CONFIG_DIR="$SCRIPT_DIR/Config"
MODELS_DIR="$SCRIPT_DIR/Models"
OUTPUT_DIR="$SCRIPT_DIR/Output"
REPOS_DIR="$SCRIPT_DIR/Repos"
STORAGE_DIR="$SCRIPT_DIR/Storage"
SYSTEM_DIR="$SCRIPT_DIR/System"
VENV_DIR="$SCRIPT_DIR/VEnv"

# Code directories
COMMANDS_DIR="$SYSTEM_DIR/commands"
HANDLERS_DIR="$SYSTEM_DIR/handlers"

# Models directories
MODELS_CODEFORMER_DIR="$MODELS_DIR/Codeformer"
MODELS_CONTROLNET_DIR="$MODELS_DIR/ControlNet"
MODELS_EMBEDDINGS_DIR="$MODELS_DIR/embeddings"
MODELS_ESRGAN_DIR="$MODELS_DIR/ESRGAN"
MODELS_GFPGAN_DIR="$MODELS_DIR/GFPGAN"
MODELS_HYPERNETWORK_DIR="$MODELS_DIR/hypernetworks"
MODELS_LDSR_DIR="$MODELS_DIR/LDSR"
MODELS_LORA_DIR="$MODELS_DIR/Lora"
MODELS_OLLAMA_DIR="$MODELS_DIR/Ollama"
MODELS_REALESRGAN_DIR="$MODELS_DIR/RealESRGAN"
MODELS_SCUNET_DIR="$MODELS_DIR/ScuNET"
MODELS_STABLEDIFFUSION_DIR="$MODELS_DIR/Stable-diffusion"
MODELS_STYLES_DIR="$MODELS_DIR/styles"
MODELS_SWINIR_DIR="$MODELS_DIR/SwinIR"
MODELS_TEXTENCODER_DIR="$MODELS_DIR/text_encoder"
MODELS_VAE_DIR="$MODELS_DIR/VAE"
MODELS_VAE_APPROX_DIR="$MODELS_DIR/VAE-approx"

# The compatible version of Python to be used within the virtual environment.
# This version should ensure that all projects function correctly. It will be
# used as a fallback when the system Python version is incompatible with the
# project being installed.
COMPATIBLE_PYTHON='python3.10'

# The project port (leave empty to use default port)
# ATTENTION: Requires root rights for ports < 1024
PROJECT_PORT=8086

function is_valid_command() {
    local command_name=$1
    [[ -f "$COMMANDS_DIR/$command_name.sh" ]]
}

#===========================================================================#
# ///////////////////////////////// MAIN ////////////////////////////////// #
#===========================================================================#

# change to the main directory
if ! cd "$SCRIPT_DIR" &>/dev/null ; then
    echo " ERROR: Failed to change directory to '$SCRIPT_DIR'."
    echo " This could be due to user '$USER' does not have sufficient permissions to access the directory."
    exit 1
fi

# load helper functions
source 'System/library/lib_directories.sh'
source 'System/library/lib_misc.sh'
source 'System/library/lib_projectdb.sh'
source 'System/library/lib_venv.sh'
load_project_db "$HANDLERS_DIR/00_database.csv"

# loop through all the script parameters
show_help=false
show_version=false
has_parameters=false
while [ $# -gt 0 ]; do
    param=$1
    case "$param" in
        -h | --help)
            show_help=true
            ;;
        -v | --version)
            show_version=true
            ;;
        -*)
            ;;
        *)
            # if the command name todavia no fue seteado,
            # set it to the current parameter
            if [[ ! $COMMAND_NAME ]]; then
                COMMAND_NAME=$param
                shift
                continue
            fi
            has_parameters=true
            ;;
    esac
    COMMAND_PARAMS+=( "$param" )
    shift
done

# if the user uses the dot format (e.g., "webui.install"),
# extract the project name and command name from the command string
if [[ "$COMMAND_NAME" == *'.'* ]]; then
    PROJECT_NAME=${COMMAND_NAME%%.*}
    COMMAND_NAME=${COMMAND_NAME#*.}
    # correct if the user mistakenly reverses the command and project name
    if is_valid_command "$PROJECT_NAME" ; then
        temp=$PROJECT_NAME
        PROJECT_NAME=$COMMAND_NAME
        COMMAND_NAME=$temp
    fi
# if the user does not use the dot format,
# then the first parameter of the command is the project name
elif is_valid_project "${COMMAND_PARAMS[0]}"; then
    PROJECT_NAME=${COMMAND_PARAMS[0]}
    COMMAND_PARAMS=( "${COMMAND_PARAMS[@]:1}" )
fi

# if the user did not enter any command, show the general help and exit
if [[ -z "$COMMAND_NAME" ]]; then
    echo "$HELP"
    exit 0
fi

# validate the command name
if ! is_valid_command "$COMMAND_NAME" ; then
    fatal_error "Invalid command - $COMMAND_NAME" \
                "To view the available commands, please run: ./$SCRIPT_NAME --help"
fi

# validate the project name
if [[ "$PROJECT_NAME" ]] && ! is_valid_project "$PROJECT_NAME"; then
    fatal_error "Project '$PROJECT_NAME' is not recognized" \
                "To see a list of available projects, use: ./$SCRIPT_NAME list"
fi

#----------------------------------------------------------------------------
# load the selected command's code
#shellcheck disable=1090
source "$COMMANDS_DIR/$COMMAND_NAME.sh"

# check if the user requested help or version for the loaded command.
# both '--help' and '--version' must have been entered without any extra params
if [[ $show_help == true && $has_parameters == false ]]; then
    echo "$HELP"
    exit 0
fi
if [[ $show_version == true && $has_parameters == false ]]; then
    echo "$SCRIPT_VER"
    exit 0
fi

# run the command code
run_command "${COMMAND_PARAMS[@]}"
exit $?


