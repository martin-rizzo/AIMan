#!/usr/bin/env bash
# File    : cmd-setdir.sh
# Brief   : Change the directories used for input and output.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 10, 2023
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
HELP="
Usage: $SCRIPT_NAME setdir <ELEMENT> <DIRECTORY>

  Change the directories used for input and output by the AI projects.

ELEMENT specifies which directory to change:
  @models   The directory where the AI models are stored.
  @output   The directory where generated files are stored.

Options:
  -h, --help     Show this help message and exit.
  -V, --version  Print version information and exit.

Examples:
  $SCRIPT_NAME setdir @models /mnt/the-ai-disk/models
  $SCRIPT_NAME setdir @output /var/output
"

function run_command() {
    enforce_constraints --no-project - "$@"
    local element=$1 directory=$2

    require_storage_dir
    if [[ $element == '@models' ]]; then
        #local old_directory
        #old_directory=$(readlink "$MODELS_DIR")
        modify_storage_link  "$MODELS_DIR"   "$directory"
        #modify_storage_link "$HOME/Models" "$directory" "$old_directory"
    fi
    if [[ $element == '@output' ]]; then
        #local old_directory
        #old_directory=$(readlink "$OUTPUT_DIR")
        modify_storage_link  "$OUTPUT_DIR"   "$directory"
        #modify_storage_link "$HOME/Output" "$directory" "$old_directory"
    fi
}
