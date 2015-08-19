# infra-imagemagick

## Intro

This repository can create an ImageMagick server from scratch, following this flow:

```yaml
 - prepare: Install prerequisites
 - init   : Refreshes current infra state and saves to terraform.tfstate
 - plan   : Shows infra changes and saves in an executable plan
 - backup : Backs up server state
 - launch : Launches virtual machines at a provider (if needed) using Terraform's ./infra.tf
 - install: Runs Ansible to install software packages & configuration templates
 - upload : Upload the application
 - setup  : Runs the ./playbook/setup.sh remotely, installing app dependencies and starting it
 - show   : Displays active platform
```

## Important files

 - [envs/production/infra.tf](envs/production/infra.tf) responsible for creating server/ram/cpu/dns
 - [playbook/playbook.yml](playbook/playbook.yml) responsible for installing APT packages
 - [control.sh](control.sh) executes each step of the flow in a logical order. Relies on Terraform and Ansible.
 - [Makefile](Makefile) provides convenience shortcuts such as `make deploy`. [Bash autocomplete](http://blog.jeffterrace.com/2012/09/bash-completion-for-mac-os-x.html) makes this sweet.
 - [env.example.sh](env.example.sh) should be copied to `env.sh` and contains the secret keys to the infra provider (amazon, google, digitalocean, etc). These keys are necessary to change infra, but not packers & config, as the SSH keys are included in this repo

## Demo

In this 2 minute demo:

 - first a server is provisioned 
 - the machine-type is changed from `c3.large` (2 cores) to `c3.xlarge` (4 cores)
 - `make deploy-infra`
 - it detects a change, replaces the server, and provisions it

![terrible](https://cloud.githubusercontent.com/assets/26752/9314635/64b6be5c-452a-11e5-8d00-74e0b023077e.gif)

as you see this is a very powerful way to set up many more servers, or deal with calamities. Since everything is in Git, changes can be reviewed, reverted, etc. `make deploy-infra`, done.

## Prerequisites

These programs are installed automatically if you miss them:

 - Terraform (local install)
 - terraform-inventory (local install, shipped with repo)
 - Ansible (via pip, asks for sudo password) 
 
(only works on 64 bits Linux & OSX)

## Create an encrypted password for use in Ansible

### Linux 

```bash
mkpasswd --method=SHA-512
```

### OSX 

```bash
pip install --upgrade passlib
python -c "from passlib.hash import sha512_crypt; import getpass; print sha512_crypt.encrypt(getpass.getpass())"
```

## Todo

- [ ] Tailormade packages/config
- [ ] State backup/restore (db, git, etc)
- [x] authorized_keys should be composed of individual files
- [x] Auto install of Ansible
- [x] Auto install of terraform-inventory
