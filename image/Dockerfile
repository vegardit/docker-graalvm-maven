#syntax=docker/dockerfile:1.4
# see https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#user-content-syntax
# see https://docs.docker.com/build/dockerfile/frontend/
# see https://docs.docker.com/engine/reference/builder/#syntax
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven
#
# https://hub.docker.com/_/debian?tab=tags&name=stable-slim
ARG BASE_IMAGE=debian:stable-slim

FROM ${BASE_IMAGE}

LABEL maintainer="Vegard IT GmbH (vegardit.com)"

USER root

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG LC_ALL=C

ARG BASE_LAYER_CACHE_KEY

RUN --mount=type=bind,source=.shared,target=/mnt/shared <<EOF

  /mnt/shared/cmd/debian-install-os-updates.sh

  echo "#################################################"
  echo "Installing tools..."
  echo "#################################################"
  apt-get install --no-install-recommends -y bc ca-certificates curl git htop jq less mc procps vim xz-utils openssh-client
  echo -e "set ignorecase
set showmatch
set novisualbell
set noerrorbells
syntax enable
set mouse-=a" > ~/.vimrc

  echo "#################################################"
  echo "Installing packages required by GraalVM..."
  echo "#################################################"
  apt-get install --no-install-recommends -y gcc libstdc++-11-dev libz-dev

  /mnt/shared/cmd/debian-cleanup.sh

EOF

ARG GRAALVM_DOWNLOAD_URL
ARG JAVA_MAJOR_VERSION
ARG UPX_COMPRESS=true

ARG BUILD_DATE
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH
ARG GIT_COMMIT_DATE
ARG GIT_REPO_URL
ARG GITHUB_TOKEN

ARG USER=user
ARG USER_HOME_DIR=/home/$USER
ARG UID=1000
ARG GID=$UID

LABEL \
  org.label-schema.schema-version="1.0" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$GIT_COMMIT_HASH \
  org.label-schema.vcs-url=$GIT_REPO_URL

RUN <<EOF

  # Function to map architecture names based on specific needs
  get_arch_name() {
    local ARCH=$1
    local TYPE_CODE=$2

    case $ARCH in
      amd64)
        case $TYPE_CODE in
          ARCH_1)
            echo "x86_64"
            ;;
          ARCH_2)
            echo "x64"
            ;;
          *)
            echo "amd64"
            ;;
        esac
        ;;
      arm64)
        case $TYPE_CODE in
          ARCH_1)
            echo "aarch64"
            ;;
          ARCH_2)
            echo "aarch64"
            ;;
          *)
            echo "arm64"
            ;;
        esac
        ;;
      *)
        echo "Unknown architecture"
        exit 1
        ;;
    esac
  }

  ARCH=$(dpkg --print-architecture)
  echo "#################################################"
  echo "${ARCH} based image will be created"
  echo "#################################################"

  echo "#################################################"
  echo "Adding default user... ${USER} with group ${GID} and home dir ${USER_HOME_DIR}}"
  echo "#################################################"
  addgroup --gid $GID $USER
  adduser --shell /bin/bash --home $USER_HOME_DIR --disabled-password --gid $GID --uid $UID --gecos "" $USER
  chown -R $USER:$GID /usr/local $USER_HOME_DIR

  echo "#################################################"
  echo "Installing latest UPX..."
  echo "#################################################"
  mkdir /opt/upx
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    upx_download_url=$(curl -fsSL https://api.github.com/repos/upx/upx/releases/latest | grep browser_download_url | grep ${ARCH}_linux.tar.xz | cut "-d\"" -f4)
  else
    upx_download_url=$(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/upx/upx/releases/latest | grep browser_download_url | grep ${ARCH}_linux.tar.xz | cut "-d\"" -f4)
  fi
  echo "Downloading [$upx_download_url]..."
  curl -fL $upx_download_url | tar Jxv -C /opt/upx --strip-components=1

  echo "#################################################"
  echo "Installing GraalVM..."
  echo "#################################################"
  mkdir /opt/graalvm
  # Extract the placeholder (ARCH, ARCH_1, ARCH_2, etc.) from the URL using a regular expression
  ARCH_PLACEHOLDER=$(echo "$GRAALVM_DOWNLOAD_URL" | grep -o 'ARCH\(_[0-9]\)\?')
  FINAL_GRAALVM_DOWNLOAD_URL=${GRAALVM_DOWNLOAD_URL//${ARCH_PLACEHOLDER}/$(get_arch_name $ARCH $ARCH_PLACEHOLDER)}
  echo "Downloading [$FINAL_GRAALVM_DOWNLOAD_URL]..."
  curl -fL "$FINAL_GRAALVM_DOWNLOAD_URL" | \
    tar zxv -C /opt/graalvm --strip-components=1 \
      --exclude=*/bin/jvisualvm \
      --exclude=*/lib/src.zip \
      --exclude=*/lib/visualvm

  /opt/graalvm/bin/gu install native-image || true # does not exist in dev

  strip --strip-unneeded \
    /opt/graalvm/bin/unpack200 `# does not exist in Java 17+`  \
    /opt/graalvm/languages/js/bin/js \
    /opt/graalvm/languages/llvm/bin/lli `# does not exist in dev` \
    /opt/graalvm/languages/llvm/native/bin/graalvm-native-* `# does not exist in dev` \
    /opt/graalvm/lib/installer/bin/gu `# does not exist in dev` \
    /opt/graalvm/lib/svm/bin/native-image || true

  if [[ $UPX_COMPRESS == "true" ]]; then
    /opt/upx/upx -9 \
      /opt/graalvm/languages/llvm/bin/lli \
      /opt/graalvm/languages/llvm/native/bin/graalvm-native-* \
      /opt/graalvm/lib/installer/bin/gu \
      /opt/graalvm/lib/svm/bin/native-image || true
      #/opt/graalvm/bin/unpack200 \
      #/opt/graalvm/languages/js/bin/js \
  fi

  export JAVA_VERSION=$(java -fullversion 2>&1 | sed -E -n 's/.* version "([^.-]*).*"/\1/p')

  echo "#################################################"
  echo "Installing latest Docker client..."
  echo "#################################################"
  docker_cli_package=$(curl -fLsS https://download.docker.com/linux/static/stable/$(get_arch_name $ARCH ARCH_1)/ | grep -oP '(?<=>)docker-\d+.\d+.\d+.tgz(?=</a>)' | tail -1)
  docker_cli_download_url=https://download.docker.com/linux/static/stable/$(get_arch_name $ARCH ARCH_1)/$docker_cli_package
  echo "Downloading [$docker_cli_download_url]..."
  curl -fL $docker_cli_download_url | tar zxv -C /usr/bin --strip-components=1 docker/docker
  # this also installs docker app and docker buildx:
  #docker_cli_package=$(curl -fsSL https://download.docker.com/linux/debian/dists/bullseye/pool/stable/$ARCH/ | grep docker-ce-cli | grep buster_$ARCH | tail -1 | grep -oP '(?<=deb">).*(?=</a>)')
  #docker_cli_download_url=https://download.docker.com/linux/debian/dists/bullseye/pool/stable/$ARCH/$docker_cli_package
  #echo "Downloading [$docker_cli_download_url]..."
  #curl -fL $docker_cli_download_url -o /tmp/docker-cli.deb
  #dpkg -i /tmp/docker-cli.deb
  #rm /tmp/docker-cli.deb
  strip --strip-unneeded /usr/bin/docker
  if [[ $UPX_COMPRESS == "true" ]]; then
    /opt/upx/upx -9 /usr/bin/docker
  fi

  echo "#################################################"
  echo "Installing latest Apache Maven..."
  echo "#################################################"
  mkdir /opt/maven
  #maven_version=$(curl -fsSL https://repo1.maven.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml | grep -oP '(?<=latest>).*(?=</latest)')
  maven_version=$(curl -fsSL https://repo1.maven.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml | grep -Ev "alpha|beta" | grep -oP '(?<=version>).*(?=</version)' | tail -n1)
  maven_download_url="https://repo1.maven.org/maven2/org/apache/maven/apache-maven/$maven_version/apache-maven-${maven_version}-bin.tar.gz"
  echo "Downloading [$maven_download_url]..."
  curl -fL $maven_download_url | tar zxv -C /opt/maven --strip-components=1

  echo "#################################################"
  echo "Installing bash-funk..."
  echo "#################################################"
  git clone https://github.com/vegardit/bash-funk --depth 1 --branch main --single-branch /opt/bash-funk
  echo "BASH_FUNK_PROMPT_PREFIX='\033[45;30m GRAALVM '" >> ~/.bashrc
  echo "source /opt/bash-funk/bash-funk.sh" >> ~/.bashrc

  echo "#################################################"
  echo "Writing build_info..."
  echo "#################################################"
  echo "
GIT_REPO:    $GIT_REPO_URL
GIT_BRANCH:  $GIT_BRANCH
GIT_COMMIT:  $GIT_COMMIT_HASH @ $GIT_COMMIT_DATE
IMAGE_BUILD: $BUILD_DATE" >/opt/build_info
  cat /opt/build_info

EOF

COPY image/settings.xml /root/.m2/settings.xml
COPY image/toolchains.xml /root/.m2/toolchains.xml

ENV \
  PATH="/opt/graalvm/bin:/opt/maven/bin:/opt/upx:${PATH}" \
  JAVA_HOME=/opt/graalvm \
  JAVA_MAJOR_VERSION=${JAVA_MAJOR_VERSION} \
  MAVEN_HOME=/opt/maven \
  M2_HOME=/opt/maven \
  MAVEN_CONFIG="/root/.m2" \
  MAVEN_OPTS="-Xmx1024m -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"

CMD "/bin/sh" "-c" "cat /opt/build_info && java --version && echo && mvn --version"

VOLUME "/root/.m2/repository"
