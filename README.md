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
 - [env.example.sh](env.example.sh) should be copied to `env.sh` and contains the secret keys to the infra provider (amazon, google, digitalocean, etc)

Not included with this repo:

 - `envs/production/infra-imagemagick.pem` - used to log in via SSH (`make console`)
 - `env.sh` - contains secrets, such as keys to infra provider

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

## Example

I enabled FTP support in this commit:
https://github.com/transloadit/infra-imagemagick/commit/eac9bd9261a9b5c8e84ef20f72997f2ea2d067af
and typed `make deploy-infra` as it involved changing firewall settings, we do that at Amazon.

I also made fetching content part of the setup script:
https://github.com/transloadit/infra-imagemagick/commit/4e02c1b31eade7a05f5351329df202e39fb33505
and typed `make deploy` as it's just a provisioning change (this one is still running as we speak, much to download)

I mistakingly made a private FTP server. I changed that in this commit:
https://github.com/transloadit/infra-imagemagick/commit/1aecde6aaed31e03299a55fa3e3d1b8b7f85aeab
and typed `make deploy`

## Tips

If you only want to run a particular Ansible job, you can use tags. For example:

```bash
IIM_ANSIBLE_TAGS=content make deploy
```

If you want to deploy with an unclean Git dir, use `unsafe` variants:

```bash
make deploy-unsafe
```

If you to SSH into the box

```bash
make console
```

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

- [ ] apache2 to support perl CGI scripts (test with http://imagemagick.transloadit.com/ImageMagick/MagickStudio/scripts/MagickStudio.cgi
- [ ] apache2 goes to /var/www/html/ImageMagick for http://imagemagick.transloadit.com and / or transloadit.imagemagick.org
- [ ] the latest ImageMagick needs to be installed (I can do this manually if needed)
- [ ] State backup/restore (db, git, etc)?
- [x] user cristy with the same public key as your ubuntu user - https://github.com/transloadit/infra-imagemagick/commit/fd616fcaea4102015f20f06b2c5688337308ae1e
- [x] Set PASV ftp traffic to a higher port range - https://github.com/transloadit/infra-imagemagick/commit/11d22ddd5561caa82e49abc11df53d20ce64d2d8
- [x] if it doesn't already, i need a daily mirror of the commands below - https://github.com/transloadit/infra-imagemagick/commit/9a101eea4b13ed844ff0bedee190c23c10c22762
- [x] lots of development packages installed fftw, djvu, fontconfig, freetype, gslib, jpeg, lcms, lqr, lzma, openexr, pango, png, rsvg, tiff, webp, wmf, and xml2 (required by ImageMagick) - https://github.com/transloadit/infra-imagemagick/commit/9949dc0a0461394e9d4cd69dec0738263ad0dca0
- [x] Instance contains an 8GB EBS device. Should be way more!
- [x] authorized_keys should be composed of individual files
- [x] Auto install of Ansible
- [x] Auto install of terraform-inventory
