@echo off
::
:: Copyright 2020-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
:: SPDX-License-Identifier: Apache-2.0
::
:: Author: Sebastian Thomschke, Vegard IT GmbH

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