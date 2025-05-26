#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

if [ $# -eq 0 ]; then
  echo "ERROR: No goals have been specified for this build. Use $(basename "${BASH_SOURCE[0]}") --help for more details."
  exit 1
fi

if [ "${1:-}" == "--help" ]; then
  echo "Builds the project with the given Maven goals inside a docker container"
  echo "with the current project mounted to /project with read/write permissions."
  echo
fi

/usr/bin/env bash "$(dirname "${BASH_SOURCE[0]}")/tools/run-in-docker.sh" mvn "$@"
