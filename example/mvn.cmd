@echo off
::
:: SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
:: SPDX-FileContributor: Sebastian Thomschke
:: SPDX-License-Identifier: Apache-2.0
:: SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

setlocal

if [%1]==[] (
  echo ERROR: No goals have been specified for this build. Use %~nx0 --help for more details.
  exit /b 1
)

if "%1"=="--help" (
  echo Builds the project with the given Maven goals inside a docker container
  echo with the current project mounted to /project with read/write permissions.
)

if "%1"=="/?" (
  call %~dpfx0 --help
  exit /b 0
)

call %~dp0tools\run-in-docker.cmd mvn %*

endlocal
