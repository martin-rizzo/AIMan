#!/usr/bin/env bash
# File    : commands/remove.sh
# Brief   : Command to remove projects from the aiman directory
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Apr 14, 2024
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
Help="
Usage: $ScriptName PROJECT.$CommandName

  remove a project from the aiman directory

Options:
    -h, --help     show command help
    -V, --version  show $ScriptName version and exit

Examples:
    $ScriptName comfyui.$CommandName
"

function run_command() {
    enforce_constraints --project "$@"

    # get project information
    project_info "$ProjectName"
    local project_dir=$(project_info @ @local_dir)
    local venv=$(project_info @ @local_venv)

    # ensure the project is installed before attempting to remove it
    if ! is_project_installed "$ProjectName"; then
        fatal_error "The project '$ProjectName' is not installed" \
            "To check which projects are installed, use: ./$ScriptName list" \
            "To install the project '$ProjectName', use: ./$ScriptName $ProjectName.install"
    fi

    # verify that the internal state is correct
    [[ -n "$RepoDir" && -n "$VEnvDir" ]] \
      || bug_report "Something is not right, \$RepoDir or \$VEnvDir appear to be empty"

    # ensure the directories are valid
    [[ "$project_dir" == "$RepoDir/"* ]] \
      || bug_report "\$project_dir seems to contain an invalid path: $project_dir"
    [[ "$venv" == "$VEnvDir/"* ]] \
      || bug_report "\$venv seems to contain an invalid path: $venv"

    # ask for user confirmation before removing the project
    if ask_confirmation \
          "Are you sure you want to remove the project '$ProjectName'?" \
          "While AIMan always tries to keep the models and data isolated and protected from each installation, it's possible that application-specific extensions or configurations may be removed."
    then
        # if the user confirmed, proceed to remove the project
        echox wait "Removing project '$ProjectName'"
        rm -rf "$project_dir" "$venv"
        echox check "Project '$ProjectName' has been removed."
    else
        # if the user cancelled, do nothing
        echox "Project removal cancelled."
    fi
}
