#!/usr/bin/env bash
#
# Copyright 2020-2021 by Vegard IT GmbH, Germany, https://vegardit.com
# SPDX-License-Identifier: Apache-2.0
#
# Author: Sebastian Thomschke, Vegard IT GmbH
#
# https://github.com/vegardit/docker-graalvm-maven
#

set -eu

#################################################
# execute script with bash if loaded with other shell interpreter
#################################################
if [ -z "${BASH_VERSINFO:-}" ]; then /usr/bin/env bash "$0" "$@"; exit; fi

set -o pipefail


#################################################
# install debug traps
#################################################
trap 'rc=$?; echo >&2 "$(date +%H:%M:%S) Error - exited with status $rc in [$BASH_SOURCE] at line $LINENO:"; cat -n $BASH_SOURCE | tail -n+$((LINENO - 3)) | head -n7' ERR

if [[ "${DEBUG:-}" == "1" ]]; then
  if [[ $- =~ x ]]; then
    # "set -x" was specified already, we only improve the PS4 in this case
    PS4='+\033[90m[$?] $BASH_SOURCE:$LINENO ${FUNCNAME[0]}()\033[0m '
  else
    # "set -x" was not specified, we use a DEBUG trap for better debug output
    set -T

    __print_debug_statement() {
      printf "\e[90m#[$?] $BASH_SOURCE:$1 ${FUNCNAME[1]}() %*s\e[35m$BASH_COMMAND\e[m\n" "$(( 2 * ($BASH_SUBSHELL + ${#FUNCNAME[*]} - 2) ))" >&2
    }
    trap '__print_debug_statement $LINENO' DEBUG
  fi
fi


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
# determine directory of current script
#################################################
project_root=$(readlink -e $(dirname "${BASH_SOURCE[0]}"))


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
# ensure Linux new line chars
#################################################
# env -i PATH="$PATH" -> workaround for "find: The environment is too large for exec()"
env -i PATH="$PATH" find "$project_root/image" -type f -exec dos2unix {} \;


#################################################
# calculate BASE_LAYER_CACHE_KEY
#################################################
# using the current date, i.e. the base layer cache (that holds system packages with security updates) will be invalidate once per day
base_layer_cache_key=$(date +%Y%m%d)


#################################################
# build the image
#################################################
echo "Building docker image [$image_name]..."
if [[ $OSTYPE == "cygwin" || $OSTYPE == "msys" ]]; then
   project_root=$(cygpath -w "$project_root")
fi

docker build "$project_root/image" \
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
# perform security audit using https://github.com/aquasecurity/trivy
#################################################
if [[ $OSTYPE != cygwin ]] && [[ $OSTYPE != msys ]]; then
  trivy_cache_dir="${TRIVY_CACHE_DIR:-$HOME/.trivy/cache}"
  trivy_cache_dir="${trivy_cache_dir/#\~/$HOME}"
  mkdir -p "$trivy_cache_dir"

  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v "$trivy_cache_dir:/root/.cache/" \
    aquasec/trivy --no-progress \
      --severity HIGH,CRITICAL \
      --exit-code 0 \
      $image_name

  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v "$project_root/.trivyignore":/.trivyignore \
    -v "$trivy_cache_dir:/root/.cache/" \
    aquasec/trivy --no-progress \
      --severity HIGH,CRITICAL \
      --ignore-unfixed \
      --ignorefile /.trivyignore \
      --exit-code 1 \
      $image_name

  sudo chown -R $USER:$(id -gn) "$trivy_cache_dir" || true
fi


#################################################
# push image with tags to remote docker image registry
#################################################
if [[ "${DOCKER_PUSH:-0}" == "1" ]]; then
  docker image tag $image_name $docker_registry/$image_name
  docker push $docker_registry/$image_name
fi


#################################################
# remove untagged images
#################################################
# http://www.projectatomic.io/blog/2015/07/what-are-docker-none-none-images/
untagged_images=$(docker images -f "dangling=true" -q --no-trunc)
[[ -n $untagged_images ]] && docker rmi $untagged_images || true


#################################################
# display some image information
#################################################
echo ""
echo "IMAGE NAME"
echo "$image_name"
echo ""
docker images "$image_repo"
echo ""
docker history "$image_name"
