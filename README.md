# Deploying Infra

Uses [Frey](https://github.com/kvz/frey) for setting up infrastructure and deploy the latest imagemagick software onto it

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

- [ ] Use `~webdev/bin/magick-local` for installing ImageMagick
- [ ] Include scripts to setup jqmagick after Webdev provides them
- [ ] Destroy & relaunch server to see if everything is correctly in playbook & infra.tf
- [x] State backup/restore (db, git, etc)?
- [x] the latest ImageMagick needs to be installed (I can do this manually if needed)
- [x] apache2 to support perl CGI scripts (test with http://imagemagick.transloadit.com/ImageMagick/MagickStudio/scripts/MagickStudio.cgi
- [x] apache2 goes to /var/www/html/ImageMagick for http://imagemagick.transloadit.com and / or transloadit.imagemagick.org
- [x] user webdev with the same public key as your ubuntu user - https://github.com/transloadit/infra-imagemagick/commit/fd616fcaea4102015f20f06b2c5688337308ae1e
- [x] Set PASV ftp traffic to a higher port range - https://github.com/transloadit/infra-imagemagick/commit/11d22ddd5561caa82e49abc11df53d20ce64d2d8
- [x] if it doesn't already, i need a daily mirror of the commands below - https://github.com/transloadit/infra-imagemagick/commit/9a101eea4b13ed844ff0bedee190c23c10c22762
- [x] lots of development packages installed fftw, djvu, fontconfig, freetype, gslib, jpeg, lcms, lqr, lzma, openexr, pango, png, rsvg, tiff, webp, wmf, and xml2 (required by ImageMagick) - https://github.com/transloadit/infra-imagemagick/commit/9949dc0a0461394e9d4cd69dec0738263ad0dca0
- [x] Instance contains an 8GB EBS device. Should be way more!
- [x] authorized_keys should be composed of individual files
- [x] Auto install of Ansible
- [x] Auto install of terraform-inventory
