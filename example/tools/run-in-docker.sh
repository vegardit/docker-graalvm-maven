#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

set -eu

#################################################
# execute script with bash if loaded with other shell interpreter
#################################################
if [ -z "${BASH_VERSINFO:-}" ]; then /usr/bin/env bash "$0" "$@"; exit; fi

set -o pipefail


#################################################
# install debug traps
#################################################
# shellcheck disable=SC2154 # rc is referenced but not assigned
trap 'rc=$?; echo >&2 "$(date +%H:%M:%S) Error - exited with status $rc in [$BASH_SOURCE] at line $LINENO:"; cat -n $BASH_SOURCE | tail -n+$((LINENO - 3)) | head -n7' ERR

if [[ "${DEBUG:-}" == "1" ]]; then
  if [[ $- =~ x ]]; then
    # "set -x" was specified already, we only improve the PS4 in this case
    PS4='+\033[90m[$?] $BASH_SOURCE:$LINENO ${FUNCNAME[0]}()\033[0m '
  else
    # "set -x" was not specified, we use a DEBUG trap for better debug output
    set -T

    __print_debug_statement() {
      printf "\e[90m#[$?] ${BASH_SOURCE[1]}:$1 ${FUNCNAME[1]}() %*s\e[35m%s\e[m\n" "$(( 2 * (BASH_SUBSHELL + ${#FUNCNAME[*]} - 2) ))" "$BASH_COMMAND" >&2
    }
    trap '__print_debug_statement $LINENO' DEBUG
  fi
fi


function printHelp() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") command [args]..."
  echo
  echo "Runs the given command in a docker container using the image specified by the"
  echo "environment variable RUN_IN_DOCKER_IMAGE with the current project mounted to"
  echo "/mnt/<project> with read/write permissions."
}

if [ $# -eq 0 ]; then
  echo "ERROR: No command specified."
  echo ""
  printHelp
fi

if [[ $1 == "--help" ]]; then
  printHelp
  exit 0
fi

export RUN_IN_DOCKER_IMAGE=${RUN_IN_DOCKER_IMAGE:-vegardit/graalvm-maven:latest-java11}

project_root=$(readlink -e "$(dirname "${BASH_SOURCE[0]}")/..")
project_name=$(basename "$project_root")

if [[ $OSTYPE == cygwin || $OSTYPE == msys ]]; then
  # the linux path in cygwin may not correspond to the linux path in docker
  # thus we construct it manually
  project_dir_in_docker=$(cygpath -w "$project_root")
  project_dir_in_docker=${project_dir_in_docker//\\//} # backslash to slash
  project_dir_in_docker=${project_dir_in_docker/:/} # remove drive colon
  project_dir_in_docker=${project_dir_in_docker,} # lowercase drive
  project_dir_in_docker=/${project_dir_in_docker} # prefix with slash
else
  project_dir_in_docker=$project_root
fi

if [[ ${GITHUB_ACTIONS:-} == "true" ]]; then
  interactive_flag="" # to error "avoid the input device is not a TTY"
else
  interactive_flag="--interactive"
fi

docker run --rm $interactive_flag --tty \
  -v "$project_dir_in_docker:/mnt/$project_name:rw" \
  -v /tmp/maven-repo:/root/.m2/repository:rw \
  -v /var/run/docker.sock:/var/run/docker.sock:rw \
  -w "/mnt/$project_name" \
  "$RUN_IN_DOCKER_IMAGE" \
  "$@"
