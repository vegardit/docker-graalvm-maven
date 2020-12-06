@echo off
::
:: Copyright (c) 2020 Vegard IT GmbH (https://vegardit.com) and contributors.
:: SPDX-License-Identifier: Apache-2.0
::
:: Author: Sebastian Thomschke, Vegard IT GmbH

if [%1]==[] (
  echo ERROR: No command specified.
  echo.
  call %~dpfx0 --help
  echo.
  echo Image Build info:
  echo -----------------
)

if "%1"=="--help" (
  echo Usage: %~n0 command [args]...
  echo.
  echo Runs the given command in a docker container using the image specified by the
  echo environment variable RUN_IN_DOCKER_IMAGE with the current project mounted to
  echo /mnt/^<project^> with read/write permissions.
  exit /b 0
)

if "%1"=="/?" (
  call %~dpfx0 --help
  exit /b 0
)

if [%RUN_IN_DOCKER_IMAGE%]==[] (
  set RUN_IN_DOCKER_IMAGE=vegardit/graalvm-maven:release
)

setlocal enabledelayedexpansion

set PROJECT_DRIVE=%~d0
set PROJECT_DRIVE=%PROJECT_DRIVE::=%
set UCASE=ABCDEFGHIJKLMNOPQRSTUVWXYZ
set LCASE=abcdefghijklmnopqrstuvwxyz
for /l %%a in (0,1,25) do (
   call set FROM=%%UCASE:~%%a,1%%
   call set TO=%%LCASE:~%%a,1%%
   call set PROJECT_DRIVE=%%PROJECT_DRIVE:!FROM!=!TO!%%
)

for %%I in ("%~p0.\..") do set "PROJECT_PATH=%%~pnI"
for %%I in ("%~p0.\..") do set "PROJECT_NAME=%%~nI"

set "PROJECT_DIR_IN_DOCKER=/%PROJECT_DRIVE%%PROJECT_PATH:\=/%"

set args=%*
if not [%1]==[] (
  REM using /bin/sh -c "%args:"=\"%" instead of simply %* allows to execute
  REM this with outer single quotes, which otherwise would fail:
  REM >  run-in-docker bash -c 'echo "Hello World"'
  set "args=/bin/sh -c ^"%args:"=\^"%^""
)

docker run --rm -it  ^
  -v %PROJECT_DIR_IN_DOCKER%:/mnt/%PROJECT_NAME%:rw ^
  -v /tmp/maven-repo:/root/.m2/repository:rw ^
  -v /var/run/docker.sock:/var/run/docker.sock:rw ^
  -w /mnt/%PROJECT_NAME% ^
  %RUN_IN_DOCKER_IMAGE% ^
  %args%

endlocal
