#!/usr/bin/env bash
# File    : helpers/directories.sh
# Brief   : Helper functions to handle aiman directories
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


# Reports on the existence of a list of subdirs within a given directory.
#
# Usage:
#   report_subdirectories DIRECTORY SUBDIRS_LIST
#
# Parameters:
#   DIRECTORY: path to the directory to check.
#   SUBDIRS_LIST: space-separated list of subdirectories to check for.
#
# Example:
#   report_subdirectories /path/to/directory "subdir1 subdir2 subdir3"
#
function report_subdirectories() {
    local directory=$1
    local subdirs_list=$2
    local -a missing_subdirs=($subdirs_list)
    local found subdir_name

    # loop through each subdirectory in the given directory
    for subdir in "$directory"/*/
    do
        # extract the name of the subdirectory without the full path
        subdir_name=$(basename "$subdir")

        # check if the dir name matches any of the subdirs we're looking for
        found=false
        for (( i=0; i<${#missing_subdirs[@]}; i++ )); do
            if [[ ${missing_subdirs[i]} == $subdir_name ]]; then
                missing_subdirs[i]=''
                found=true
            fi
        done
        # report on whether the subdirectory was found or not
        if $found; then
            echoex check "   --    /$subdir_name"
        else
            echoex warn  "unknown  /$subdir_name"
        fi
    done
    # check if any of the subdirectories were not found and report them
    for subdir in "${missing_subdirs[@]}"; do
        if [[ $subdir ]]; then
            subdir_name=$(basename "$subdir")
            echoex error "missing  /$subdir_name"
        fi
    done
}

# Prints a shortened version of a given directory path.
#
# Usage:
#   print_short_dir [readlink] DIRECTORY
#
# Parameters:
#   readlink (optional): If specified, the `readlink` command will be used to
#                        resolve any symbolic links in the path to the directory.
#   DIRECTORY: the path to the directory to print.
#
# Example:
#   print_short_dir /path/to/directory
#   print_short_dir readlink /path/to/directory
#
function print_short_dir() {
    local directory
    case "$1" in
        readlink) directory=$(readlink "$2") ;;
        *)        directory=$1               ;;
    esac
    if [[ $directory == "$MainDir"* ]]; then
        echo ".${directory#$MainDir}"
    elif [[ $directory == "$HOME"* ]]; then
        echo "~${directory#$HOME}"
    else
        echo "$directory"
    fi
}


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

# Ensures the existence of a symbolic link
#
# Usage:
#   require_soft_link <link_name> <target> [force]
#
# Parameters:
#   - link_name: The name of the symbolic link to be checked or created.
#   - target   : The target path that the symbolic link should point to.
#   - force (optional): If set to 1, it can convert a dir to a symbolic link.
#
# Example:
#   require_soft_link ~/mylink ~/target_folder
#   (ensure sym-link named 'mylink' exists, pointing to 'target_folder')
#
function require_soft_link() {
    local link_name=$1 target=$2 force=${3:-0}

    if [[ -L $link_name ]]; then
        echoex check "soft link '$link_name' already exists."
        return
    elif [[ ! -e $link_name ]]; then
        echoex wait "creating soft link '$link_name'."
        ln -s "$target" "$link_name"
    elif [[ $force -eq 1 && -d $link_name ]]; then
        echoex wait "converting directory in a soft link $link_name"
        mv "$link_name" "$link_name-old"
        ln -s "$target" "$link_name"
    else
        fatal_error "'$link_name' must be a soft link."
    fi
}

function modify_storage_link() {
    local link_name=$1 directory=$2 old_directory=$3
    if [[ ! -L "$link_name" ]]; then
       return
    fi
    if [[ -n $old_directory ]]; then
        curr_target=$(readlink "$link_name")
        if [[ $curr_target != $old_directory ]]; then
            return
        fi
    fi
    # remove any trailing slash from the path to avoid issues
    if [ "${directory: -1}" = "/" ]; then
        directory="${directory::-1}"
    fi
    ln -nsf "$directory" "$link_name"
    echoex check "$link_name -> $directory"
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


