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

cmdRsync=$(echo rsync \
  --verbose \
  --recursive \
  --perms \
  --owner \
  --group \
  --times \
  --links \
  --sparse \
  --times \
  --compress)

sudo mkdir -p /var/ftp/pub/ImageMagick
sudo ${cmdRsync} --exclude 'cache/' rsync://magick.imagemagick.org/magick_html/ /var/www/html/ImageMagick
sudo rm -rf /var/www/html/ImageMagick/cache/*.php
sudo ${cmdRsync} --exclude 'cache/' rsync://magick.imagemagick.org/magick7_html/ /var/www/html/ImageMagick-7
sudo rm -rf /var/www/html/ImageMagick-7/cache/*.php
sudo cp /etc/magick/MagickStudio.pm /var/www/html/ImageMagick/MagickStudio/scripts
sudo cp /etc/magick/policy.xml /usr/local/etc/ImageMagick-6/policy.xml
sudo ${cmdRsync} --delete rsync://magick.imagemagick.org/magick_usage/ /var/www/html/ImageMagick/Usage
sudo ${cmdRsync} --delete rsync://magick.imagemagick.org/magick_ftp/ /var/ftp/pub/ImageMagick
sudo chown -R webdev.www-data /var/www
