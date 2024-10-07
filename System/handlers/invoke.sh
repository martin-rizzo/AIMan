#!/usr/bin/env bash
# File    : project-invoke.sh
# Brief   : Manages the local copy of the "invoke" project.
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



function install() {
    local venv=$1 project_dir=$2 repo=$3 hash=$4
    shift 4

    require_system_command git
    require_storage_dir
    require_venv "$venv"

    clone_repository "$repo" "$hash" "$project_dir"
    safe_chdir "$project_dir"

    # export INVOKEAI_ROOT=$project_dir

    # NVIDIA GPU
    #virtual_python "$venv" !pip install -e .[xformers] --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu117

    ## AMD GPU
    #virtual_python "$venv" !pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/rocm5.4.2

    ## CPU
    #virtual_python "$venv" !pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/cpu

    ## configure / downloads models
    #virtual_python "$venv" !invokeai-configure --root_dir "$project_dir"

    ## launch
    #virtual_python "$venv" !invokeai --web --root_dir "$project_dir"

}


