#!/usr/bin/env bash
# infra-imagemagick. Copyright (c) 2015, Transloadit Ltd.

set -o pipefail
# set -o errexit
set -o nounset
# set -o xtrace

# Set magic variables for current FILE & DIR
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

version="${1:-${IIM_IMAGEMAGICK_VERSION}}"
dirname="ImageMagick-${version}"
filename="${dirname}.tar.lz"
cpuCores=$(egrep '^processor' /proc/cpuinfo |wc -l)

pushd "/usr/src"
  if [ ! -f "${filename}" ]; then
    wget "http://www.imagemagick.org/download/releases/${filename}"
  fi
  if [ ! -d "${dirname}" ]; then
    tar --lzip -xvf ImageMagick-6.9.2-0.tar.lz
  fi
  pushd "${dirname}"
    ./configure \
      --prefix /usr/local/
    make -j "${cpuCores}"
    make install
  popd
popd

touch "/home/ubuntu/built-imagemagick-${version}.txt"
