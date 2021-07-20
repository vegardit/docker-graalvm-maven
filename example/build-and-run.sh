#!/usr/bin/env bash
#
# Copyright 2020-2021 by Vegard IT GmbH, Germany, https://vegardit.com
# SPDX-License-Identifier: Apache-2.0
#
# Author: Sebastian Thomschke, Vegard IT GmbH

project_dir="$(dirname ${BASH_SOURCE[0]})"

echo "Building native linux binary via Maven in docker..."
/usr/bin/env bash $project_dir/mvn.sh clean package

echo "Executing native linux binary in docker..."
/usr/bin/env bash $project_dir/tools/run-in-docker.sh target/example
