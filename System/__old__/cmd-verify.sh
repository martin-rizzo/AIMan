#!/usr/bin/env bash
# File    : cmd-verify.sh
# Brief   : Command to verify aiman elements for consistency.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 10, 2023
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
Help="
Usage: $ScriptName verify [ELEMENT]

Verify the specified ELEMENT for consistency.

Elements to verify:
    @models       The models directory and its subdirectories
    @output       The output directory

Options:
    -h, --help     Show this help message and exit.
    -V, --version  Print version information and exit.

Examples:    
    $ScriptName verify @models   # verify the models directory
    $ScriptName verify @output   # verify the output directory
"


function __verify_models() {
    local models_dir=$(print_short_dir "$ModelsDir")
    local models_real_dir=$(print_short_dir readlink "$ModelsDir")
    
    require_storage_directory
    echo "  @models: $models_dir"
    echo "      ---> $models_real_dir"
    echo
    report_subdirectories "$ModelsDir" "$ValidModelsSubdirs"
}

function __verify_output() {
    local output_dir=$(print_short_dir "$OutputDir")
    local output_real_dir=$(print_short_dir readlink "$OutputDir")
    
    require_storage_directory
    echo "  @output: $output_dir"
    echo "      ---> $output_real_dir"
    echo
}

function run_command() {
    local options=$1 elements=$2
    
    if [[ $options ]]; then
        echoex error "unrecognized options: $options"
        exit 1
    fi
    for element in $elements; do
        case $element in
            @models) __verify_models ;;
            @output) __verify_output ;;
            *)
              echoex error "unrecognized element: $element"
              exit 1
              ;;
        esac
    done
}
