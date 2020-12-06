#!/usr/bin/env bash
#
# Copyright 2020 by Vegard IT GmbH, Germany, https://vegardit.com
# SPDX-License-Identifier: Apache-2.0
#
# Author: Sebastian Thomschke, Vegard IT GmbH

if [ $# -eq 0 ]; then
  echo "ERROR: No goals have been specified for this build. Use $(basename ${BASH_SOURCE[0]}) --help for more details."
  exit 1
fi

if [ "${1:-}" == "--help" ]; then
  echo "Builds the project with the given Maven goals inside a docker container"
  echo "with the current project mounted to /project with read/write permissions."
  echo
fi

/usr/bin/env bash "$(dirname ${BASH_SOURCE[0]})/tools/run-in-docker.sh" mvn "$@"
