#!/usr/bin/env bash
# File    : project-invoke.sh
# Brief   : Controls the local copy of the "invoke" project.
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 5, 2023
# Repo    : https://github.com/martin-rizzo/AIAppManager
# License : MIT
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                      Stable Diffusion Prompt Viewer
#      A plugin for "Eye of GNOME" that displays SD embedded prompts.
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

    aiman_git_clone https://github.com/invoke-ai/InvokeAI.git
    activate_virtual_env
    
    # NVIDIA GPU
    pip install -e .[xformers] --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu117
    
    ## AMD GPU
    #pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/rocm5.4.2
    
    ## CPU
    #pip install -e . --use-pep517 --extra-index-url https://download.pytorch.org/whl/cpu
    
}

function launch() {

    activate_virtual_env
    invokeai --web
    
}


