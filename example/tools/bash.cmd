@echo off
::
:: SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
:: SPDX-FileContributor: Sebastian Thomschke
:: SPDX-License-Identifier: Apache-2.0
:: SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

setlocal

if "%1"=="--help" (
  echo Starts a Bash console in a docker container using
  echo with the current project mounted to /project with read/write permissions.
  echo.
)

if "%1"=="/?" (
  call %~dpfx0 --help
  exit /b 0
)

call %~dp0run-in-docker.cmd bash %*

endlocal