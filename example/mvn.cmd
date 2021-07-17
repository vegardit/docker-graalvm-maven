@echo off
::
:: Copyright 2020-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
:: SPDX-License-Identifier: Apache-2.0
::
:: Author: Sebastian Thomschke, Vegard IT GmbH

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
