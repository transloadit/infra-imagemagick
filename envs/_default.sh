#!/usr/bin/env bash
# Environment tree:
#
#   _default.sh
#   ├── development.sh
#   │   └── test.sh
#   └── production.sh
#       └── staging.sh
#
# This provides DRY flexibilty, but in practice I recommend using mainly
# development.sh and production.sh, and duplication keys between them
# so you can easily compare side by side.
# Then just use _default.sh, test.sh, staging.sh for tweaks, to keep things
# clear.
#
# These variables are mandatory and have special meaning
#
#   - NODE_APP_PREFIX="MYAPP" # filter and nest vars starting with MYAPP right into your app
#   - NODE_ENV="production"   # the environment your program thinks it's running
#   - DEPLOY_ENV="staging"    # the machine you are actually running on
#   - DEBUG=*.*               # Used to control debug levels per module
#
# After getting that out of the way, feel free to start hacking on, prefixing all
# vars with MYAPP a.k.a an actuall short abbreviation of your app name.

export APP_PREFIX="IIM"
export NODE_APP_PREFIX="${APP_PREFIX}"

export IIM_DOMAIN="imagemagick1.transloadit.com"

export IIM_APP_DIR="/srv/current"
export IIM_APP_NAME="imagemagick"
export IIM_APP_PORT="80"
export IIM_HOSTNAME="$(uname -n)"

export IIM_SERVICE_USER="www-data"
export IIM_SERVICE_GROUP="www-data"

# See readme for how to update pass
export IIM_FTP_USER="webdev"
#      IIM_FTP_PASS <-- is set in ./env.sh, which is kept out of Git
export IIM_FTP_PASS_ENC='$6$rounds=656000$8ACvi9Ng2HX6wYPA$VAxXDlN6bqwsyOQ/U8lwe9OIFBpuFP.1UcuGrvuH/0cQpk4flb9liMwYfIqctdgmJabq0QevycGnUP9yMD5SV.'

export IIM_SSH_KEY_NAME="infra-imagemagick"
export IIM_SSH_USER="ubuntu"
export IIM_SSH_EMAIL="hello@transloadit.com"
export IIM_SSH_KEY_FILE="${__envdir}/infra-imagemagick.pem"
export IIM_SSH_KEYPUB_FILE="${__envdir}/infra-imagemagick.pub"
export IIM_SSH_KEYPUB=$(echo "$(cat "${IIM_SSH_KEYPUB_FILE}" 2>/dev/null)") || true
export IIM_SSH_KEYPUB_FINGERPRINT="$(ssh-keygen -lf ${IIM_SSH_KEYPUB_FILE} | awk '{print $2}')"

export IIM_ANSIBLE_TAGS="${IIM_ANSIBLE_TAGS:-}"

export IIM_VERIFY_TIMEOUT=5
