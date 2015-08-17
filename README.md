# infra-imagemagick

## Intro

This repository can create an ImageMagick server from scratch, following this flow:

```yaml
 - prepare: Install prerequisites
 - init   : Refreshes current infra state and saves to terraform.tfstate
 - plan   : Shows infra changes and saves in an executable plan
 - launch : Launches virtual machines at a provider (if needed) using Terraform's ./infra.tf
 - install: Runs Ansible to install software packages & configuration templates
 - upload : Upload the application
 - setup  : Runs the ./payload/setup.sh remotely, installing app dependencies and starting it
 - show   : Displays active platform
```

![terrible](https://cloud.githubusercontent.com/assets/26752/9314635/64b6be5c-452a-11e5-8d00-74e0b023077e.gif)


## Important files

 - <envs/production/infra.tf> responsible for creating server/ram/cpu/dns
 - <payload/playbook.yml> responsible for installing APT packages
 - <control.sh> executes terraform, ansible, etc, in a logical order
 - <Makefile> provides convenience shortcuts such as `make deploy`
 - <env.example.sh> should be copied to `env.sh` and contain the secret keys to the infra provider (amazon, google, digitalocean, etc)

## Prerequisites

### Terraform

Installed automatically if needed

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
