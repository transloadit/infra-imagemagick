# Rename this file to env.sh, it will be kept out of Git.
# So suitable for adding secret keys and such

# Set magic variables for current FILE & DIR
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__rootdir="${__dir}"

export NODE_ENV="${NODE_ENV:-development}"
export DEPLOY_ENV="${DEPLOY_ENV:-production}"
export DEBUG="frey:*"

export FREY_DOMAIN="imagemagick.transloadit.com"
# export FREY_ENCRYPTION_SECRET="***"

# See readme for how to update pass
# export FREY_FTP_USER="webdev"
#      FREY_FTP_PASS <-- is set in ./env.sh, which is kept out of Git
# export FREY_FTP_PASS_ENC='***'
# export FREY_IMAGEMAGICK_VERSION="6.9.2-0"
