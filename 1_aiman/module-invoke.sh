#!/usr/bin/env bash



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


