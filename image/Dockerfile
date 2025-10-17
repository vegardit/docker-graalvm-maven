#syntax=docker/dockerfile:1
# see https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md
# see https://docs.docker.com/engine/reference/builder/#syntax
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven

# https://hub.docker.com/_/debian/tags?name=stable-slim
ARG BASE_IMAGE=debian:stable-slim

#############################################################
# build final image
#############################################################

# https://github.com/hadolint/hadolint/wiki/DL3006 Always tag the version of an image explicitly
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG LC_ALL=C

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# https://github.com/hadolint/hadolint/wiki/DL3002 Last USER should not be root
# hadolint ignore=DL3002
USER root

ARG BASE_LAYER_CACHE_KEY

# https://github.com/hadolint/hadolint/wiki/DL3008 Pin versions in apt-get
# hadolint ignore=DL3008
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
  apt-get install --no-install-recommends -y gcc libstdc++-13-dev libz-dev

  /mnt/shared/cmd/debian-cleanup.sh

EOF

ARG GRAALVM_DOWNLOAD_URL
ARG JAVA_MAJOR_VERSION
ARG UPX_COMPRESS=true

ARG OCI_authors
ARG OCI_title
ARG OCI_description
ARG OCI_source
ARG OCI_revision
ARG OCI_version
ARG OCI_created

ARG GIT_BRANCH
ARG GIT_COMMIT_DATE

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL \
  org.opencontainers.image.title="$OCI_title" \
  org.opencontainers.image.description="$OCI_description" \
  org.opencontainers.image.source="$OCI_source" \
  org.opencontainers.image.revision="$OCI_revision" \
  org.opencontainers.image.version="$OCI_version" \
  org.opencontainers.image.created="$OCI_created"

LABEL maintainer="$OCI_authors"

ARG USER=user
ARG USER_HOME_DIR=/home/$USER
ARG UID=1000
ARG GID=$UID

RUN --mount=type=secret,id=github_token,required=false <<EOF

  ARCH=$(dpkg --print-architecture)

  echo "#################################################"
  echo "$ARCH based image will be created"
  echo "#################################################"

  # Function to resolve the arch ID for binary packages
  function resolve_arch() {
    local ARCH_PLACEHOLDER; ARCH_PLACEHOLDER=$1
    # strip the leading '{{ARCH_':
    APP_ID="${ARCH_PLACEHOLDER#\{\{ARCH_}"
    # strip the trailing '}}'':
    APP_ID="${APP_ID%\}\}}"

    case $ARCH in
      amd64)
        case $APP_ID in
          DOCKER_CLIENT) echo "x86_64" ;;
          GRAAL)         echo "x64" ;;
          GRAAL_DEV)     echo "amd64" ;;
          GRAAL_LEGACY)  echo "amd64" ;;
          *)             echo "amd64" ;;
        esac
        ;;
      arm64)
        case $APP_ID in
          DOCKER_CLIENT) echo "aarch64" ;;
          GRAAL)         echo "aarch64" ;;
          GRAAL_DEV)     echo "aarch64" ;;
          GRAAL_LEGACY)  echo "aarch64" ;;
          *)             echo "arm64" ;;
        esac
        ;;
      *)
        echo "Unknown architecture"
        exit 1
        ;;
    esac
  }

  echo "#################################################"
  echo "Adding default user... $USER with group $GID and home dir $USER_HOME_DIR"
  echo "#################################################"
  addgroup --gid "$GID" "$USER"
  adduser --shell /bin/bash --home "$USER_HOME_DIR" --disabled-password --gid "$GID" --uid "$UID" --gecos "" "$USER"
  chown -R "$USER:$GID" /usr/local "$USER_HOME_DIR"

  echo "#################################################"
  echo "Installing latest UPX..."
  echo "#################################################"
  mkdir /opt/upx
  if [[ -f /run/secrets/github_token ]]; then
     auth=(-H "Authorization: Bearer $(cat /run/secrets/github_token)")
  fi

  upx_download_url=$(curl -fsSL "${auth[@]:-}" https://api.github.com/repos/upx/upx/releases/latest | grep browser_download_url | grep "${ARCH}_linux.tar.xz" | cut "-d\"" -f4)

  echo "Downloading [$upx_download_url]..."
  curl -fL "$upx_download_url" | tar Jxv -C /opt/upx --strip-components=1

  echo "#################################################"
  echo "Installing GraalVM..."
  echo "#################################################"
  mkdir /opt/graalvm
  # Extract {{ARCH_xyz}} placeholder from the URL
  ARCH_PLACEHOLDER=$(echo "$GRAALVM_DOWNLOAD_URL" | grep -oE '\{\{(ARCH(_[_[:alnum:]]+)?)\}\}')
  FINAL_GRAALVM_DOWNLOAD_URL=${GRAALVM_DOWNLOAD_URL//${ARCH_PLACEHOLDER}/$(resolve_arch "$ARCH_PLACEHOLDER")}
  echo "Downloading [$FINAL_GRAALVM_DOWNLOAD_URL]..."
  curl -fL "$FINAL_GRAALVM_DOWNLOAD_URL" | \
    tar zxv -C /opt/graalvm --strip-components=1 \
      --exclude=*/bin/jvisualvm \
      --exclude=*/lib/src.zip \
      --exclude=*/lib/visualvm

  /opt/graalvm/bin/gu install native-image || true # may not exist for some distributions/dev builds
  /opt/graalvm/bin/gu install wasm || true # may not exist for some distributions/dev builds

  strip --strip-unneeded \
    /opt/graalvm/bin/unpack200 `# does not exist in Java 17+`  \
    /opt/graalvm/languages/js/bin/js \
    /opt/graalvm/languages/llvm/bin/lli `# does not exist in dev` \
    /opt/graalvm/languages/llvm/native/bin/graalvm-native-* `# does not exist in dev` \
    /opt/graalvm/languages/wasm/bin/wasm `# wasm launcher, if installed` \
    /opt/graalvm/lib/installer/bin/gu `# does not exist in dev` \
    /opt/graalvm/lib/svm/bin/native-image || true

  if [[ $UPX_COMPRESS == "true" ]]; then
    /opt/upx/upx -9 \
      /opt/graalvm/languages/llvm/bin/lli \
      /opt/graalvm/languages/llvm/native/bin/graalvm-native-* \
      /opt/graalvm/languages/wasm/bin/wasm \
      /opt/graalvm/lib/installer/bin/gu \
      /opt/graalvm/lib/svm/bin/native-image || true
      #/opt/graalvm/bin/unpack200 \
      #/opt/graalvm/languages/js/bin/js \
  fi

  JAVA_MAJOR_VERSION=$(/opt/graalvm/bin/java -fullversion 2>&1 | sed -E -n 's/.* version "([^.-]*).*"/\1/p')
  export JAVA_MAJOR_VERSION

  echo "#################################################"
  echo "Installing latest Docker client..."
  echo "#################################################"
  docker_cli_package=$(curl -fLsS "https://download.docker.com/linux/static/stable/$(resolve_arch "{{ARCH_DOCKER_CLIENT}}")/" | grep -oP '(?<=>)docker-\d+.\d+.\d+.tgz(?=</a>)' | tail -1)
  docker_cli_download_url=https://download.docker.com/linux/static/stable/$(resolve_arch "{{ARCH_DOCKER_CLIENT}}")/$docker_cli_package
  echo "Downloading [$docker_cli_download_url]..."
  curl -fL "$docker_cli_download_url" | tar zxv -C /usr/bin --strip-components=1 docker/docker
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
  maven_version=$(curl -fsSL https://repo1.maven.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml | grep -Ev "alpha|beta|rc" | grep -oP '(?<=version>).*(?=</version)' | tail -n1)
  maven_download_url=https://repo1.maven.org/maven2/org/apache/maven/apache-maven/$maven_version/apache-maven-${maven_version}-bin.tar.gz
  echo "Downloading [$maven_download_url]..."
  curl -fL "$maven_download_url" | tar zxv -C /opt/maven --strip-components=1

  echo "#################################################"
  echo "Installing bash-funk..."
  echo "#################################################"
  git clone https://github.com/vegardit/bash-funk --depth 1 --branch main --single-branch /opt/bash-funk
  # shellcheck disable=SC2028  # echo may not expand escape sequences. Use printf
  echo   "BASH_FUNK_PROMPT_PREFIX='\033[45;30m GRAALVM '" >> ~/.bashrc
  echo "source /opt/bash-funk/bash-funk.sh" >> ~/.bashrc

  echo "#################################################"
  echo "Writing build_info..."
  echo "#################################################"
  cat <<EOT >/opt/build_info
GIT_REPO:    $OCI_source
GIT_BRANCH:  $GIT_BRANCH
GIT_COMMIT:  $OCI_revision @ $GIT_COMMIT_DATE
IMAGE_BUILD: $OCI_created
EOT
  cat /opt/build_info

EOF

COPY image/settings.xml /root/.m2/settings.xml
COPY image/toolchains.xml /root/.m2/toolchains.xml

ENV \
  PATH="/opt/graalvm/bin:/opt/maven/bin:/opt/upx:$PATH" \
  JAVA_HOME=/opt/graalvm \
  JAVA_MAJOR_VERSION=$JAVA_MAJOR_VERSION \
  MAVEN_HOME=/opt/maven \
  M2_HOME=/opt/maven \
  MAVEN_CONFIG="/root/.m2" \
  MAVEN_OPTS="-Xmx1024m -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"

CMD ["/bin/sh", "-c", "cat /opt/build_info && java --version && echo && mvn --version"]

VOLUME "/root/.m2/repository"
