#!/usr/bin/env bash
# File    : helper-dir.sh
# Brief   : Internal directories
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : May 6, 2023
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


function change_to_main_directory() {
    cd "$MainDir" &> /dev/null
}

function change_to_repo_directory() {
    if [[ ! -e "$RepoDir" ]]; then
        echoex wait "creating directory $RepoDir"
        mkdir -p "$RepoDir"
    elif [[ ! -d "$RepoDir" ]]; then
        echoex fatal "$RepoDir must be a directory"
        exit 1
    fi
    cd "$RepoDir"
}

function require_directory() {
    local directory=$1
    if [[ ! -e $directory ]]; then
        echoex wait "creating directory $directory"
        mkdir -p "$directory"
    elif [[ ! -d $directory ]]; then
        echoex fatal "$directory must be a directory"
        exit 1
    fi
}

function require_soft_link() {
    local link_name=$1 target=$2
    
    if [[ ! -e $link_name ]]; then
        echoex wait "creating link $link_name"
        ln -s "$target" "$link_name"
    elif [[ ! -L $link_name ]]; then
        echoex fatal "$link_name must be a soft link"
        exit 1
    fi
}

function modify_storage_link() {
    local link_name=$1 new_directory=$2 old_directory=$3
    if [[ ! -L "$link_name" ]]; then
       return
    fi
    if [[ -n $old_directory ]]; then
        curr_target=$(readlink "$link_name")
        if [[ $curr_target != $old_directory ]]; then
            return
        fi
    fi
    ln -sf "$new_directory" "$link_name"
    echoex check "$link_name" -> "$new_directory"
}


function set_storage_dir() {
    local store=$1 new_directory=$2 old_directory
    if [[ $store == '@models' ]]; then
        old_directory=$(readlink "$MainDir/Models")
        modify_storage_link "$MainDir/Models" "$new_directory"
        modify_storage_link "$HOME/Models"    "$new_directory" "$old_directory"
    fi
    if [[ $store == '@output' ]]; then
        old_directory=$(readlink "$MainDir/Output")
        modify_storage_link "$MainDir/Output" "$new_directory"
        modify_storage_link "$HOME/Output"    "$new_directory" "$old_directory"
    fi
}

function require_storage_directory() {
    require_directory "$StorageDir"
    require_directory "$StorageDir/Models"
    require_directory "$StorageDir/Output"
    require_soft_link "$MainDir/Models" "$StorageDir/Models"
    require_soft_link "$MainDir/Output" "$StorageDir/Output"
    if [[ $USER = 'aiman' ]]; then
        require_soft_link "$HOME/Models" "$StorageDir/Models"
        require_soft_link "$HOME/Output" "$StorageDir/Output"
    fi
}


