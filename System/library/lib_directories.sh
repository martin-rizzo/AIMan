#!/usr/bin/env bash
# File    : library/lib_directories.sh
# Brief   : Utilities for managing directories and symbolic links
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
#
# FUNCTIONS:
#   - report_subdirectories() : Reports on the existence of a list of subdirs.
#   - print_short_dir()       : Prints the shortened version of a path.
#   - require_directory()     : Ensures the existence of a directory.
#   - require_symlink()       : Ensures the existence of a symbolic link.
#   - require_storage_dir()   :
#   - modify_storage_link()   :
#
#-----------------------------------------------------------------------------


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
            echox check "   --    /$subdir_name"
        else
            echox warn  "unknown  /$subdir_name"
        fi
    done
    # check if any of the subdirectories were not found and report them
    for subdir in "${missing_subdirs[@]}"; do
        if [[ $subdir ]]; then
            subdir_name=$(basename "$subdir")
            echox error "missing  /$subdir_name"
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
    if [[ $directory == "$SCRIPT_DIR"* ]]; then
        echo ".${directory#$SCRIPT_DIR}"
    elif [[ $directory == "$HOME"* ]]; then
        echo "~${directory#$HOME}"
    else
        echo "$directory"
    fi
}

# Ensures the existence of a directory.
#
# Usage:
#   require_directory <directory>
#
# Parameters:
#   - directory: the path of the directory to be created if it does not exist.
#
# Example:
#   require_directory "/opt/myapp/data"
#
function require_directory() {
    local directory=$1
    if [[ ! -e $directory ]]; then
        echox wait "creating directory $directory"
        mkdir -p "$directory"
    elif [[ ! -d $directory ]]; then
        echox fatal "$directory must be a directory"
        exit 1
    fi
}


# Ensures the existence of a symbolic link
#
# Usage:
#   require_symlink <link_name> <target> [mode]
#
# Parameters:
#   - link_name : The name of the symbolic link to be checked or created.
#   - target    : The target path that the symbolic link should point to.
#   - mode      : The mode of operation, can be one of the following
#      '--safe'       : This is the default mode, where the function will
#                       not modify any existing files or directories.
#      '--convert-dir': If the link_name already exists as a directory,
#                       the function will convert it to a symbolic link.
#      '--move-dir'   : If the link_name already exists as a directory,
#                       the function will move the contents of the directory
#                       into the new symbolic link.
#      '--move-file'  : If the link_name already exists as a file,
#                       the function will move the contents of the file
#                       into the new symbolic link.
# Example:
#   require_symlink ~/mylink ~/target_folder
#   (ensures a symbolic link named 'mylink' exists, pointing to 'target_folder')
#
function require_symlink() {
    local link_name=$1 target=$2 mode=${3:---safe}
    local convert_dir=false move_dir=false move_file=false

    # 'link_name' should be a symbolic link name
    # it cannot be a path that includes directories or subdirectories !!
    link_name=${link_name#./}
    link_name=${link_name#/}
    [[ $link_name == *"/"* ]] \
     && bug_report "The 'require_symlink()' function does not support 'link_name' to be a path: '$link_name'"

    # set different flags depending on the 'mode' parameter
    case "$mode" in
        '--safe')
            ;;
        '--convert-dir')
            convert_dir=true
            ;;
        '--move-dir')
            move_dir=true
            ;;
        "--move-file")
            # if the target file doesn't exist,
            # try to generate it from the original file
            if [[ ! -e $target ]]; then
                if [[ -f $link_name ]]; then
                    # copy the original file to the target
                    # (cp+rm ensures the target file has the correct permissions)
                    cp "$link_name" "$target"
                    rm "$link_name"
                else
                    # create a new empty file in the target
                    touch "$target"
                fi
            fi
            move_file=true
            ;;
        *)
            fatal_error \
                "Unknown mode parameter in require_symlink(): '$mode'"  \
                "This is an internal error likely caused by a mistake in the code"
            ;;
    esac

    if [[ ! -e $link_name ]]; then
        echox wait "creating symlink '$link_name'."
        ln -s "$target" "$link_name"

    elif [[ -L $link_name ]]; then
        echox check "symlink '$link_name' already exists."

    elif [[ $convert_dir == true && -d $link_name ]]; then
        echox wait "converting directory '$link_name' to a symlink."
        mv "$link_name" "_0LD_-$link_name"
        ln -s "$target" "$link_name"

    elif [[ $move_dir == true && -d $link_name ]]; then
        echox wait "converting '$link_name' to a symlink and moving its contents inside."
        local temp_dir
        temp_dir=$(mktemp -d)
        mv "$link_name"/* "$temp_dir"
        rm -rf "$link_name"
        ln -s "$target" "$link_name"
        mv "$temp_dir"/* "$link_name"
        rm -rf "$temp_dir"

    else
        fatal_error "Unable to create symlink because a file or directory with the same name already exists ($link_name)." \
                    "You may try deleting it if you consider it disposable."
    fi
}

# TODO:
#  - require_storage
#  - update_storage_symlink 'Models' <DIRECTORY>
#  - update_storage_symlink 'Output' <DIRECTORY>

function require_storage_dir() {
    pushd . > /dev/null
    require_directory "$STORAGE_DIR"
    require_directory "$STORAGE_DIR/Config"
    require_directory "$STORAGE_DIR/Models"
    require_directory "$STORAGE_DIR/Output"
    safe_chdir "$SCRIPT_DIR"
    require_symlink 'Config' "$STORAGE_DIR/Config"
    require_symlink 'Models' "$STORAGE_DIR/Models"
    require_symlink 'Output' "$STORAGE_DIR/Output"
#     if [[ $USER =~ ^aiman[0-9]?$ ]]; then
#         safe_chdir "$HOME"
#         require_symlink 'Models' "$STORAGE_DIR/Models"
#         require_symlink 'Output' "$STORAGE_DIR/Output"
#     fi
    popd > /dev/null
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
    echox check "$link_name -> $directory"
}


