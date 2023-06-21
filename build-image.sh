#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: Apache-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/vegardit/docker-graalvm-maven
#

shared_lib="$(dirname $0)/.shared"
[ -e "$shared_lib" ] || curl -sSf https://raw.githubusercontent.com/vegardit/docker-shared/v1/download.sh?_=$(date +%s) | bash -s v1 "$shared_lib" || exit 1
source "$shared_lib/lib/build-image-init.sh"


#################################################
# specify target docker registry/repo
#################################################
graalvm_version=${GRAALVM_VERSION:-latest}
java_major_version=${GRAALVM_JAVA_VERSION:-11}
docker_registry=${DOCKER_REGISTRY:-docker.io}
image_repo=${DOCKER_IMAGE_REPO:-vegardit/graalvm-maven}
image_tag="${DOCKER_IMAGE_TAG:-$graalvm_version-java$java_major_version}" # e.g. dev-java17, latest-java17, 22.3.2-java17

#################################################
# determine GraalVM download URL
#################################################
case $graalvm_version in
   dev)   graalvm_version=$(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/graalvm/graalvm-ce-dev-builds/releases/latest | grep "tag_name" | cut -d'"' -f4)
          graalvm_url="https://github.com/graalvm/graalvm-ce-dev-builds/releases/download/${graalvm_version}/graalvm-community-java${java_major_version}-linux-amd64-dev.tar.gz"
          ;;

   *dev*) graalvm_url="https://github.com/graalvm/graalvm-ce-dev-builds/releases/download/${graalvm_version}/graalvm-community-java${java_major_version}-linux-amd64-dev.tar.gz"
          ;;

   latest) case $java_major_version in
              11) graalvm_version="22.3.2";
                  graalvm_url="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${graalvm_version}/graalvm-ce-java11-linux-amd64-${graalvm_version}.tar.gz"
                  ;;
              *)  graalvm_version=$(curl -sSfL -N https://github.com/graalvm/graalvm-ce-builds/tags | grep -oP "releases/tag/jdk-\K${java_major_version}.[^=\"]+" | head -n1)
                  graalvm_url="https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${graalvm_version}/graalvm-community-jdk-${graalvm_version}_linux-x64_bin.tar.gz"
                  ;;
           esac
           ;;

   *)      graalvm_url="https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${graalvm_version}/graalvm-community-jdk-${graalvm_version}_linux-x64_bin.tar.gz"
           image_tag="${DOCKER_IMAGE_TAG:-$graalvm_version}" # e.g. 17.0.7
           ;;
esac
echo "Effective GRAALVM_VERSION: $graalvm_version"

image_name=$image_repo:$image_tag


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
   --build-arg GITHUB_TOKEN="$GITHUB_TOKEN" \
   -t $image_name \
   "$@"


#################################################
# push image with tags to remote docker image registry
#################################################
if [[ "${DOCKER_PUSH:-0}" == "1" ]]; then
   docker image tag $image_name $docker_registry/$image_name
   docker push $docker_registry/$image_name

   if [[ $graalvm_version != *dev* ]]; then
      if [[ $java_major_version == "11" ]]; then
         docker image tag $image_name $docker_registry/$image_repo:$graalvm_version-java$java_major_version  # e.g. 22.3.2-java11
         docker push $docker_registry/$image_repo:$graalvm_version-java$java_major_version
      else
         docker image tag $image_name $docker_registry/$image_repo:$graalvm_version # e.g. 17.0.7
         docker push $docker_registry/$image_repo:$graalvm_version
      fi
   fi
fi
