#!/usr/bin/env bash
# infra-imagemagick. Copyright (c) 2015, Transloadit Ltd.
#
# This file:
#
#  - Runs on a workstation
#  - Looks at environment for cloud provider credentials, keys and their locations
#  - Takes a 1st argument, the step:
#    - prepare: Install prerequisites
#    - init   : Refreshes current infra state and saves to terraform.tfstate
#    - plan   : Shows infra changes and saves in an executable plan
#    - backup : Backs up server state
#    - launch : Launches virtual machines at a provider (if needed) using Terraform's ./infra.tf
#    - install: Runs Ansible to install software packages & configuration templates
#    - upload : Upload the application
#    - setup  : Runs the ./payload/setup.sh remotely, installing app dependencies and starting it
#    - show   : Displays active platform
#  - Takes an optional 2nd argument: "done". If it's set, only 1 step will execute
#  - Will cycle through all subsequential steps. So if you choose 'upload', 'setup' will
#    automatically be executed
#  - Looks at IIM_DRY_RUN environment var. Set it to 1 to just show what will happen
#
# Run as:
#
#  ./control.sh upload
#
# Authors:
#
#  - Kevin van Zonneveld <kevin@transloadit.com>

set -o pipefail
set -o errexit
set -o nounset
# set -o xtrace

if [ -z "${DEPLOY_ENV}" ]; then
  echo "Environment ${DEPLOY_ENV} not recognized. "
  echo "Please first source envs/development/config.sh or source envs/production/config.sh"
  exit 1
fi

# Set magic variables for current FILE & DIR
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

__rootdir="${__dir}"
__terraformDir="${__rootdir}/terraform"
__envdir="${__rootdir}/envs/${DEPLOY_ENV}"
__payloaddir="${__rootdir}/payload"
__terraformExe="${__terraformDir}/terraform"

__planfile="${__envdir}/terraform.plan"
__statefile="${__envdir}/terraform.tfstate"
__playbookfile="${__payloaddir}/playbook.yml"

__terraformVersion="0.6.3"

### Functions
####################################################################################

function syncUp() {
  [ -z "${host:-}" ] && host="$(${__terraformExe} output public_address)"
  chmod 600 ${IIM_SSH_KEYPUB_FILE}
  chmod 600 ${IIM_SSH_KEY_FILE}
  rsync \
   --archive \
   --delete \
   --exclude=.git* \
   --exclude=.DS_Store \
   --exclude=node_modules \
   --exclude=terraform.* \
   --itemize-changes \
   --checksum \
   --no-times \
   --no-group \
   --no-motd \
   --no-owner \
   --rsh="ssh \
    -i \"${IIM_SSH_KEY_FILE}\" \
    -l ${IIM_SSH_USER} \
    -o CheckHostIP=no \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no" \
   ${@:2} \
  ${host}:${1}
}

function syncDown() {
  [ -z "${host:-}" ] && host="$(${__terraformExe} output public_address)"
  chmod 600 ${IIM_SSH_KEYPUB_FILE}
  chmod 600 ${IIM_SSH_KEY_FILE}
  rsync \
   --archive \
   --delete \
   --exclude=.git* \
   --exclude=.java* \
   --exclude=.* \
   --exclude=*.log \
   --exclude=*.log.* \
   --exclude=*.txt \
   --exclude=org.jenkinsci.plugins.ghprb.GhprbTrigger.xml \
   --exclude=*.bak \
   --exclude=*.hpi \
   --exclude=node_modules \
   --exclude=.DS_Store \
   --exclude=plugins \
   --exclude=builds \
   --exclude=lastStable \
   --exclude=lastSuccessful \
   --exclude=*secret* \
   --exclude=*identity* \
   --exclude=nextBuildNumber \
   --exclude=userContent \
   --exclude=nodes \
   --exclude=updates \
   --exclude=terraform.* \
   --itemize-changes \
   --checksum \
   --no-times \
   --no-group \
   --no-motd \
   --no-owner \
   --no-perms \
   --rsh="ssh \
    -i \"${IIM_SSH_KEY_FILE}\" \
    -l ${IIM_SSH_USER} \
    -o CheckHostIP=no \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no" \
  ${host}:${1} \
  ${2}
}

function remote() {
  [ -z "${host:-}" ] && host="$(${__terraformExe} output public_address)"
  chmod 600 ${IIM_SSH_KEYPUB_FILE}
  chmod 600 ${IIM_SSH_KEY_FILE}
  ssh ${host} \
    -i "${IIM_SSH_KEY_FILE}" \
    -l ${IIM_SSH_USER} \
    -o UserKnownHostsFile=/dev/null \
    -o CheckHostIP=no \
    -o StrictHostKeyChecking=no "${@:-}"
}

# Waits on first host, then does the rest in parallel
# This is so that the leader can be setup, and then all the followers can join
function inParallel () {
  cnt=0
  for host in $(${__terraformExe} output public_addresses); do
    let "cnt = cnt + 1"
    if [ "${cnt}" = 1 ]; then
      # wait on leader leader
      ${@}
    else
      ${@} &
    fi
  done

  fail=0
  for job in $(jobs -p); do
    # echo ${job}
    wait ${job} || let "fail = fail + 1"
  done
  if [ "${fail}" -ne 0 ]; then
    exit 1
  fi
}


### Vars
####################################################################################

dryRun="${IIM_DRY_RUN:-0}"
step="${1:-prepare}"
afterone="${2:-}"
enabled=0


### Runtime
####################################################################################

pushd "${__envdir}" > /dev/null

if [ "${step}" = "remote" ]; then
  remote ${@:2}
  exit ${?}
fi
if [ "${step}" = "facts" ]; then
  ANSIBLE_HOST_KEY_CHECKING=False \
  TF_STATE="${__statefile}" \
    ansible all \
      --user="${IIM_SSH_USER}" \
      --private-key="${IIM_SSH_KEY_FILE}" \
      --inventory-file="$(which terraform-inventory)" \
      --module-name=setup \
      --args='filter=ansible_*'

  exit ${?}
fi
if [ "${step}" = "backup" ]; then
  syncDown "/var/lib/jenkins/" "${__dir}/payload/templates/"
  exit ${?}
fi
if [ "${step}" = "restore" ]; then
  remote "sudo /etc/init.d/redis-server stop || true"
  remote "sudo addgroup ubuntu redis || true"
  remote "sudo chmod -R g+wr /var/lib/redis"
  syncUp "/var/lib/redis/dump.rdb" "./data/redis-dump.rdb"
  remote "sudo chown -R redis.redis /var/lib/redis"
  remote "sudo /etc/init.d/redis-server start"
  exit ${?}
fi

processed=""
for action in "prepare" "init" "plan" "backup" "launch" "install" "upload" "setup" "show"; do
  [ "${action}" = "${step}" ] && enabled=1
  [ "${enabled}" -eq 0 ] && continue
  if [ -n "${processed}" ] && [ "${afterone}" = "done" ]; then
    break
  fi

  echo "--> ${IIM_HOSTNAME} - ${action}"

  if [ "${action}" = "prepare" ]; then
    os="linux"
    if [[ "${OSTYPE}" == "darwin"* ]]; then
      os="darwin"
    fi

    # Install brew/wget on OSX
    if [ "${os}" = "darwin" ]; then
      [ -z "$(which brew 2>/dev/null)" ] && ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      [ -z "$(which wget 2>/dev/null)" ] && brew install wget
    fi

    # Install Terraform
    arch="amd64"
    zipFile="terraform_${__terraformVersion}_${os}_${arch}.zip"
    url="https://dl.bintray.com/mitchellh/terraform/${zipFile}"
    dir="${__terraformDir}"
    mkdir -p "${dir}"
    pushd "${dir}" > /dev/null
      if [ "$(echo $("${__terraformExe}" version))" != "Terraform v${__terraformVersion}" ]; then
        rm -f "${zipFile}" || true
        wget "${url}"
        unzip -o "${zipFile}"
        rm -f "${zipFile}"
      fi
      "${__terraformExe}" version |grep "Terraform v${__terraformVersion}"
    popd > /dev/null

    # Install SSH Keys
    if [ ! -f "${IIM_SSH_KEY_FILE}" ]; then
      echo -e "\n\n" | ssh-keygen -t rsa -C "${IIM_SSH_EMAIL}" -f "${IIM_SSH_KEY_FILE}"
      echo "You may need to add ${IIM_SSH_KEYPUB_FILE} to the Digital Ocean"
      export IIM_SSH_KEYPUB=$(echo "$(cat "${IIM_SSH_KEYPUB_FILE}")") || true
      # Digital ocean requires this:
      export IIM_SSH_KEYPUB_FINGERPRINT="$(ssh-keygen -lf ${IIM_SSH_KEYPUB_FILE} | awk '{print $2}')"
    fi
    if [ ! -f "${IIM_SSH_KEYPUB_FILE}" ]; then
      ssh-keygen -yf "${IIM_SSH_KEY_FILE}" > "${IIM_SSH_KEYPUB_FILE}"
    fi

    processed="${processed} ${action}" && continue
  fi

  terraformArgs=""
  terraformArgs="${terraformArgs} -var IIM_AWS_SECRET_KEY=${IIM_AWS_SECRET_KEY}"
  terraformArgs="${terraformArgs} -var IIM_AWS_ACCESS_KEY=${IIM_AWS_ACCESS_KEY}"
  terraformArgs="${terraformArgs} -var IIM_AWS_ZONE_ID=${IIM_AWS_ZONE_ID}"
  terraformArgs="${terraformArgs} -var IIM_DOMAIN=${IIM_DOMAIN}"
  terraformArgs="${terraformArgs} -var IIM_SSH_KEYPUB=\"${IIM_SSH_KEYPUB}\""
  terraformArgs="${terraformArgs} -var IIM_SSH_USER=${IIM_SSH_USER}"
  terraformArgs="${terraformArgs} -var IIM_SSH_KEY_FILE=${IIM_SSH_KEY_FILE}"
  terraformArgs="${terraformArgs} -var IIM_SSH_KEY_NAME=${IIM_SSH_KEY_NAME}"

  if [ "${action}" = "init" ]; then
    # if [ ! -f ${__statefile} ]; then
    #   echo "Nothing to refresh yet."
    # else
    bash -c "${__terraformExe} refresh ${terraformArgs}" || true
    # fi
  fi

  if [ "${action}" = "plan" ]; then
    rm -f ${__planfile}
    bash -c "${__terraformExe} plan -refresh=false ${terraformArgs} -out ${__planfile}"
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "backup" ]; then
    # Save state before possibly destroying machine
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "launch" ]; then
    if [ -f ${__planfile} ]; then
      echo "--> Press CTRL+C now if you are unsure! Executing plan in ${IIM_VERIFY_TIMEOUT}s..."
      [ "${dryRun}" -eq 1 ] && echo "--> Dry run break" && exit 1
      sleep ${IIM_VERIFY_TIMEOUT}
      # exit 1
      ${__terraformExe} apply ${__planfile}
      git commit -m "Save infra state" "${__statefile}" || true
      git commit -m "Save infra state" "${__statefile}.backup" || true
    else
      echo "Skipping, no changes. "
    fi
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "install" ]; then
    ANSIBLE_HOST_KEY_CHECKING=False \
    TF_STATE="${__statefile}" \
      ansible-playbook \
        --user="${IIM_SSH_USER}" \
        --private-key="${IIM_SSH_KEY_FILE}" \
        --inventory-file="$(which terraform-inventory)" \
        --sudo \
      "${__playbookfile}"

    # inParallel "remote" "bash -c \"source ~/payload/env/config.sh && sudo -E bash ~/payload/install.sh\""
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "upload" ]; then
    # Upload/Download app here
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "setup" ]; then
    # Restart services
    processed="${processed} ${action}" && continue
  fi

  if [ "${action}" = "show" ]; then
    echo "http://${IIM_DOMAIN}:${IIM_APP_PORT}"
    # for host in $(${__terraformExe} output public_addresses); do
    #   echo " - http://${host}:${IIM_APP_PORT}"
    # done
    processed="${processed} ${action}" && continue
  fi
done
popd > /dev/null

echo "--> ${IIM_HOSTNAME} - completed:${processed} : )"
