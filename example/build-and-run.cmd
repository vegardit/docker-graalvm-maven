@echo off
::
:: Copyright (c) 2020 Vegard IT GmbH (https://vegardit.com) and contributors.
:: SPDX-License-Identifier: Apache-2.0
::
:: Author: Sebastian Thomschke, Vegard IT GmbH

set PROJECT_DIR=%~dp0

echo Building native linux binary via Maven in docker...
call %PROJECT_DIR%\mvn.cmd clean package

echo Executing native linux binary in docker...
call %PROJECT_DIR%tools\run-in-docker.cmd target/example
