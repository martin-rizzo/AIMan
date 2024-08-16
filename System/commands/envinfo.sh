#!/usr/bin/env bash
#shellcheck disable=SC2154
# File    : commands/envinfo.sh
# Brief   : Command to display details about each project
# Author  : Martin Rizzo | <martinrizzo@gmail.com>
# Date    : Aug 16, 2023
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
#shellcheck disable=SC2034 # '$Help' es utilizado por el script principal
Help="
Usage: $ScriptName PROJECT.$CommandName

  Display details about a project.

Options:
  -h, --help     show command help
  -V, --version  show $ScriptName version and exit

Examples:
  $ScriptName webui.$CommandName
"

# Función para obtener la versión de un paquete
get_version() {
    local packages=$1 package_name=$2
    local version
    version=$(grep "$package_name" <<< "$packages" | awk '{print $2}')
    if [[ ! "$version" ]]; then
        echo "--"
        return 1
    else
        version=$(echo "$version" | sed -E 's/^(.*\..*)\..*$/\1/')
        echo "$version"
        return 0
    fi
}


function run_command() {
    enforce_constraints --project --no-params "$@"
    local venv python_ver

    # load the project information requerida by the user
    # (once the information is loaded, '@' can be used as the project name)
    project_info "$ProjectName"

    # solamente puede mostrar informacion del entorno virtual
    # de aquellos proyectos que ya se encuentran instalados
    if ! is_project_installed @; then
        fatal_error "El proyecto '$ProjectName' no esta instalado." \
                    "To install the project '$ProjectName', use: ./$ScriptName $ProjectName.install"
    fi

    # activando el entorno virtual
    venv=$(project_info @ @local_venv)
    virtual_python "$venv"

    # extrayendo versiones de cada paquete
    packages=$(virtual_python !pip list)
    python_ver=$(virtual_python --version)
    python_ver=$(get_version "$python_ver" Python)
    cuda_ver=$(get_version "$packages" cuda-runtime)
    torch_ver=$(get_version "$packages" '^torch[^a-zA-Z0-9]')
    bab_ver=$(get_version "$packages" '^bitsandbytes[^a-zA-Z0-9]')

    LIB_LOG_PADDING=' '
    message
    message "venv dir.    : $venv"
    message "Python       : $python_ver"
    message "Cuda         : $cuda_ver"
    message "Torch        : $torch_ver"
    message "Bitsandbytes : $bab_ver"
    message
    #echo "$packages"
}
