#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

project_dir="$(dirname ${BASH_SOURCE[0]})"

echo "Building native linux binary via Maven in docker..."
/usr/bin/env bash $project_dir/mvn.sh clean package

echo "Executing native linux binary in docker..."
/usr/bin/env bash $project_dir/tools/run-in-docker.sh target/example
