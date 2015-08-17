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
 - setup  : Runs the ./payload/setup.sh remotely, installing app dependencies and starting it
 - show   : Displays active platform
```

## Important files

 - <envs/production/infra.tf> responsible for creating server/ram/cpu/dns
 - <payload/playbook.yml> responsible for installing APT packages
 - <control.sh> executes terraform, ansible, etc, in a logical order
 - <Makefile> provides convenience shortcuts such as `make deploy`
 - <env.example.sh> should be copied to `env.sh` and contain the secret keys to the infra provider (amazon, google, digitalocean, etc)

## Demo

In this 2 minute demo:

 - first a server is provisioned 
 - the machine-type is changed from `c3.large` (2 cores) to `c3.xlarge` (4 cores)
 - `make deploy-infra`
 - it detects a change, replaces the server, and provisions it

![terrible](https://cloud.githubusercontent.com/assets/26752/9314635/64b6be5c-452a-11e5-8d00-74e0b023077e.gif)

as you see this is a very powerful way to set up many more servers, or deal with calamities. Since everything is in Git, changes can be reviewed, reverted, etc. `make deploy-infra`, done.

## Prerequisites

### Terraform

Installed automatically if missing.

### terraform-inventory

#### OSX

brew install https://raw.github.com/adammck/terraform-inventory/master/homebrew/terraform-inventory.rb

### Ansible

#### OSX

```bash
sudo -HE easy_install pip
sudo -HE pip install --upgrade pip
sudo -HE CFLAGS=-Qunused-arguments CPPFLAGS=-Qunused-arguments pip install --upgrade ansible
```

## Todo

- [ ] Auto install of Ansible
- [ ] Auto install of terraform-inventory
- [ ] Tailormade packages/config
- [ ] State backup/restore (db, git, etc)
