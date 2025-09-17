# docker-graalvm-maven <a href="https://github.com/vegardit/docker-graalvm-maven/" title="GitHub Repo"><img height="30" src="https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/github.svg?sanitize=true"></a>

[![Build Status](https://github.com/vegardit/docker-graalvm-maven/workflows/Build/badge.svg "GitHub Actions")](https://github.com/vegardit/docker-graalvm-maven/actions?query=workflow%3ABuild)
[![License](https://img.shields.io/github/license/vegardit/docker-graalvm-maven.svg?label=license)](#license)
[![Docker Pulls](https://img.shields.io/docker/pulls/vegardit/graalvm-maven.svg)](https://hub.docker.com/r/vegardit/graalvm-maven)
[![Docker Stars](https://img.shields.io/docker/stars/vegardit/graalvm-maven.svg)](https://hub.docker.com/r/vegardit/graalvm-maven)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.1%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

1. [What is it?](#what-is-it)
1. [Usage](#usage)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

Opinionated docker image based on the [Debian](https://www.debian.org/) docker image [`debian:stable-slim`](https://hub.docker.com/_/debian?tab=tags&name=stable-slim) to
build native Linux binaries from Java [Maven](http://maven.apache.org/) projects using [GraalVM CE](https://www.graalvm.org/) [native-image](https://www.graalvm.org/reference-manual/native-image/) feature.

It is automatically built **weekly** to include the latest OS security fixes.

The image comes pre-installed with latest releases of:
- [Apache Maven](http://maven.apache.org/download.cgi) build automation tool for Java projects
- [Docker CE (Community Edition)](https://download.docker.com/linux/debian/dists/bullseye/pool/stable/amd64/) command line client
- [GraalVM CE (Community Edition) for JDK 11, 17, 21 or 25](https://www.graalvm.org/downloads/) with [native-image](https://www.graalvm.org/reference-manual/native-image/) extension
- tools:
  - [bash-funk](https://github.com/vegardit/bash-funk) Bash toolbox with adaptive Bash prompt
  - [git](https://packages.debian.org/en/git) command line client
  - [htop](https://htop.dev/) interactive process viewer
  - [mc](https://midnight-commander.org/) aka Midnight Commander
  - [openssh-client](https://packages.debian.org/en/openssh-client) SSH command line client
  - [upx](https://upx.github.io/) executable packer
  - [Vim](https://www.vim.org/) text editor



Further we add the user `user` with uid `1000` and gid `1000` as non-privileged user in order to run without root privileges.
Note, that the user is not set to 1000 within the docker image. Specify the uid to be `1000` with your docker run command.


## <a name="tags"></a>Docker image tagging scheme

|Tag|Description
|-|-
|<pre>:latest-java11<br>:latest-java17<br>:latest-java21<br>:latest-java25</pre> | latest available [GraalVM CE releases](https://github.com/graalvm/graalvm-ce-builds/releases) for the given JDK
|<pre>:dev-java25</pre> | latest available [GraalVM CE development builds](https://github.com/graalvm/graalvm-ce-dev-builds/releases) for the given JDK
|<pre>:XX.Y.Z</pre> | the given GraalVM CE releases (e.g. `17.0.8` for JDK 17 and `21.0.0` for JDK 21) following GraaLVM's [new version naming scheme](https://medium.com/graalvm/a-new-graalvm-release-and-new-free-license-4aab483692f5#8822).
|<pre>:XX.Y.Z-java11<br>:XX.Y.Z-java17</pre> | the given GraalVM CE releases (e.g. `22.3.2-java11`) following GraaLVM's **old version naming scheme**

See all available tags at https://hub.docker.com/r/vegardit/graalvm-maven/tags



## Usage

### Building a local Maven project

To build a Maven project located on your local workstation with via this docker image you can do:

1. On Linux:
    ```bash
    $ cd ~/myproject
    $ docker run --rm -it \
      -v $PWD:/mnt/myproject:rw \
      -w /mnt/myproject \
      vegardit/graalvm-maven:latest-java17 \
      mvn clean package
    ```

1. On Windows:
    ```batch
    C:> cd C:\Users\MyUser\myproject
    C:\Users\MyUser\myproject> docker run --rm -it ^
      -v /c/Users/MyUser/myproject:/mnt/myproject:rw ^
      -w /mnt/myproject ^
      vegardit/graalvm-maven:latest-java17 ^
      mvn clean package
    ```

Also checkout the [example](example) project which provides convenient batch/bash script wrappers and outlines how to do compile Java projects to native Linux binaries.


### Using custom Maven settings.xml

You can use a custom Maven [settings.xml](https://maven.apache.org/settings.html) by mounting it to `/root/.m2/settings.xml`

```bash
    $ cd ~/myproject
    $ docker run --rm -it \
      -v /path/to/my/settings.xml:/root/.m2/settings.xml:ro \
      -v $PWD:/mnt/myproject:rw \
      -w /mnt/myproject \
      vegardit/graalvm-maven:latest-java17 \
      mvn clean package
```


### Running docker commands inside the container

This image has the docker command line client installed, which allows you to run other docker containers as part of your build toolchain using a
[docker-out-of-docker (DooD)](http://blog.teracy.com/2017/09/11/how-to-use-docker-in-docker-dind-and-docker-outside-of-docker-dood-for-local-ci-testing/) approach
by mounting the `/var/run/docker.sock` into the container.

```bash
$ cd ~/myproject
$ docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock:rw \
  -v $PWD:/mnt/myproject:rw \
  vegardit/graalvm-maven:latest-java17 \
  docker run --rm hello-world
```


### Caching local Maven repository between runs

You can a local folder to `/root/.m2/repository` to cache the downloaded artifacts between Maven runs

```bash
    $ cd ~/myproject
    $ docker run --rm -it \
      -v /path/to/my/local/repository:/root/.m2/repository:rw \
      -v $PWD:/mnt/myproject:rw \
      -w /mnt/myproject \
      vegardit/graalvm-maven:latest-java17 \
      mvn clean package
```



## <a name="license"></a>License

All files in this repository are released under the [Apache License 2.0](LICENSE.txt).

Individual files contain the following tag instead of the full license text:
```
SPDX-License-Identifier: Apache-2.0
```

This enables machine processing of license information based on the SPDX License Identifiers that are available here: https://spdx.org/licenses/.
