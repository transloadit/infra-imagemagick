# infra-imagemagick

## Intro

This repository can create an ImageMagick server from scratch.

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
