#!/usr/bin/env bash
#
# Copyright 2020-2021 by Vegard IT GmbH, Germany, https://vegardit.com
# SPDX-License-Identifier: Apache-2.0
#
# Author: Sebastian Thomschke, Vegard IT GmbH
#
# https://github.com/vegardit/docker-graalvm-maven
#

shared_lib="$(dirname $0)/.shared"
[ -e "$shared_lib" ] || curl -sSf https://raw.githubusercontent.com/vegardit/docker-shared/v1/download.sh?_=$(date +%s) | bash -s v1 "$shared_lib" || exit 1
source "$shared_lib/lib/build-image-init.sh"


#################################################
# specify target docker registry/repo
#################################################
graalvm_version=${GRAALVM_VERSION:-release}
java_major_version=${GRAAVM_JAVA_VERSION:-11}
docker_registry=${DOCKER_REGISTRY:-docker.io}
image_repo=${DOCKER_IMAGE_REPO:-vegardit/graalvm-maven}
image_tag=${DOCKER_IMAGE_TAG:-$graalvm_version}
image_name=$image_repo:$image_tag


#################################################
# determine GraalVM download URL
#################################################
case $graalvm_version in \
   latest)  graalvm_version=$(curl -sS https://api.github.com/repos/graalvm/graalvm-ce-dev-builds/releases/latest | grep "tag_name" | cut -d'"' -f4) ;& \
   *dev*)   graalvm_url="https://github.com/graalvm/graalvm-ce-dev-builds/releases/download/${graalvm_version}/graalvm-ce-java${java_major_version}-linux-amd64-dev.tar.gz" ;; \
   release) graalvm_version=$(curl -sS https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/latest | grep "tag_name" | cut -d'"' -f4 | cut -d'-' -f2) ;& \
   *)       graalvm_url="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${graalvm_version}/graalvm-ce-java${java_major_version}-linux-amd64-${graalvm_version}.tar.gz" ;; \
esac
echo "Effective GRAALVM_VERSION: $graalvm_version"


#################################################
# build the image
#################################################
echo "Building docker image [$image_name]..."
if [[ $OSTYPE == "cygwin" || $OSTYPE == "msys" ]]; then
   project_root=$(cygpath -w "$project_root")
fi

DOCKER_BUILDKIT=1 docker build "$project_root" \
   --file "image/Dockerfile" \
   --progress=plain \
   --pull \
   `# using the current date as value for BASE_LAYER_CACHE_KEY, i.e. the base layer cache (that holds system packages with security updates) will be invalidate once per day` \
   --build-arg BASE_LAYER_CACHE_KEY=$base_layer_cache_key \
   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
   --build-arg GRAALVM_DOWNLOAD_URL="$graalvm_url" \
   --build-arg JAVA_MAJOR_VERSION="$java_major_version" \
   --build-arg UPX_COMPRESS="${UPX_COMPRESS:-true}" \
   --build-arg GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" \
   --build-arg GIT_COMMIT_DATE="$(date -d @$(git log -1 --format='%at') --utc +'%Y-%m-%d %H:%M:%S UTC')" \
   --build-arg GIT_COMMIT_HASH="$(git rev-parse --short HEAD)" \
   --build-arg GIT_REPO_URL="$(git config --get remote.origin.url)" \
   -t $image_name \
   "$@"


#################################################
# push image with tags to remote docker image registry
#################################################
if [[ "${DOCKER_PUSH:-0}" == "1" ]]; then
   docker image tag $image_name $docker_registry/$image_name

   docker push $docker_registry/$image_name
fi
