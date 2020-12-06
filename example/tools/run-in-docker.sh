#!/usr/bin/env bash
#
# Copyright 2020 by Vegard IT GmbH, Germany, https://vegardit.com
# SPDX-License-Identifier: Apache-2.0
#
# Author: Sebastian Thomschke, Vegard IT GmbH

set -eu

#################################################
# execute script with bash if loaded with other shell interpreter
#################################################
if [ -z "${BASH_VERSINFO:-}" ]; then /usr/bin/env bash "$0" "$@"; exit; fi

set -o pipefail

function printHelp() {
  echo "Usage: $(basename ${BASH_SOURCE[0]}) command [args]..."
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

if [ "$1" == "--help" ]; then
  printHelp
  exit 0
fi

export RUN_IN_DOCKER_IMAGE=${RUN_IN_DOCKER_IMAGE:-vegardit/graalvm-maven:release}

project_root=$(readlink -e "$(dirname ${BASH_SOURCE[0]})/..")
project_name=$(basename "$project_root")

if [[ $OSTYPE == "cygwin" || $OSTYPE == "msys" ]]; then
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
  -v $project_dir_in_docker:/mnt/$project_name:rw \
  -v /tmp/maven-repo:/root/.m2/repository:rw \
  -v /var/run/docker.sock:/var/run/docker.sock:rw \
  -w /mnt/$project_name \
  $RUN_IN_DOCKER_IMAGE \
  "$@"
