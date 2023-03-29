@echo off
::
:: SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
:: SPDX-FileContributor: Sebastian Thomschke
:: SPDX-License-Identifier: Apache-2.0
:: SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

set PROJECT_DIR=%~dp0

echo Building native linux binary via Maven in docker...
call %PROJECT_DIR%\mvn.cmd clean package

echo Executing native linux binary in docker...
call %PROJECT_DIR%tools\run-in-docker.cmd target/example
