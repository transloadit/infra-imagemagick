global {
  appname = "infra-imagemagick"
  ssh {
    key_dir = "./ssh"
  }
  ansiblecfg {
    privilege_escalation {
      become = true
    }
    defaults {
      host_key_checking = false
      ansible_managed = "Ansible managed"
    }
    ssh_connection {
      pipelining = true
    }
  }
}

infra provider aws {
  access_key = "${var.FREY_AWS_ACCESS_KEY}"
  region     = "us-east-1"
  secret_key = "${var.FREY_AWS_SECRET_KEY}"
}

infra variable {
  amis {
    type = "map"
    default {
      "us-east-1" = "ami-fd378596"
    }
  }
  region {
    default = "us-east-1"
  }
  ip_all {
    default = "0.0.0.0/0"
  }
  ip_kevin {
    default = "62.163.187.106/32"
  }
  ip_marius {
    default = "84.146.0.0/16"
  }
  ip_webdev {
    default = "50.251.58.9/32"
  }
}

infra output {
  endpoint {
    value = "http://transloadit.imagemagick.org:80"
  }
  public_address {
    value = "${aws_instance.infra-imagemagick.0.public_dns}"
  }
  public_addresses {
    value = "${join("\n", aws_instance.infra-imagemagick.*.public_dns)}"
  }
}

infra resource aws_instance "infra-imagemagick" {
  ami             = "${lookup(var.amis, var.region)}"
  instance_type   = "c3.xlarge"
  key_name        = "infra-imagemagick"
  security_groups = ["fw-infra-imagemagick-main"]
  connection {
    key_file = "{{{config.global.ssh.privatekey_file}}}"
    user     = "{{{config.global.ssh.user}}}"
  }
  tags {
    "Name" = "imagemagick1.transloadit.com"
  }
}

infra resource aws_route53_record "www" {
  name    = "${var.FREY_DOMAIN}"
  records = ["imagemagick1.transloadit.com"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = "${var.FREY_AWS_ZONE_ID}"
}

infra resource aws_route53_record "www1" {
  name    = "imagemagick1.transloadit.com"
  records = ["${aws_instance.infra-imagemagick.0.public_dns}"]
  ttl     = "300"
  type    = "CNAME"
  zone_id = "${var.FREY_AWS_ZONE_ID}"
}

infra resource aws_security_group "fw-infra-imagemagick-main" {
  description = "Infra Imagemagick"
  name        = "fw-infra-imagemagick-main"
  ingress {
    cidr_blocks = ["${var.ip_all}"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["${var.ip_all}"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    cidr_blocks = ["${var.ip_all}"]
    from_port   = 20
    protocol    = "tcp"
    to_port     = 21
  }
  ingress {
    cidr_blocks = ["${var.ip_all}"]
    from_port   = 50000
    protocol    = "tcp"
    to_port     = 50999
  }
}

install {
  playbooks {
    hosts = ["infra-imagemagick"]
    name  = "Install infra-imagemagick"
    roles {
      role        = "{{{init.paths.roles_dir}}}/apt/1.3.0"
      apt_install = [
        "apache2",
        "apg",
        "apt-file",
        "build-essential",
        "cpanminus",
        "curl",
        "fftw-dev",
        "git-core",
        "htop",
        "iotop",
        "libdjvulibre-dev",
        "libfontconfig-dev",
        "libfreetype6-dev",
        "libgs-dev",
        "libjpeg-dev",
        "liblcms-dev",
        "liblqr-dev",
        "liblzma-dev",
        "libopenexr-dev",
        "libpango1.0-dev",
        "libpcre3",
        "libperl-dev",
        "libpng-dev",
        "librsvg2-dev",
        "libtiff-dev",
        "libwebp-dev",
        "libwmf-dev",
        "libxml2-dev",
        "logtail",
        "lzip",
        "mlocate",
        "mtr",
        "mysql-client-5.5",
        "phpbb3",
        "psmisc",
        "telnet",
        "vim",
        "vsftpd",
        "wget",
      ]
    }
    roles {
      role = "{{{init.paths.roles_dir}}}/unattended-upgrades/1.3.0"
    }
    tasks {
      authorized_key = "user=ubuntu key='{{ lookup('file', 'templates/webdev-dsa.pub.j2') }}'"
      name           = "Access | Add authorized_keys for user ubuntu"
    }
    tasks {
      name = "Access | Add user webdev"
      user = "name=webdev home=/home/webdev shell=/bin/bash comment='Webdev' group=www-data"
    }
    tasks {
      authorized_key = "user=webdev key='{{ lookup('file', 'templates/webdev-dsa.pub.j2') }}'"
      name           = "Access | Add authorized_keys for user webdev"
    }
    tasks {
      name = "Common | Add convenience shortcut wtf"
      lineinfile {
        dest = "/home/ubuntu/.bashrc"
        line = "alias wtf='sudo tail -f /var/log/*{log,err} /var/log/{dmesg,messages,*{,/*}{log,err}}'"
      }
    }
  }
}

setup {
  playbooks {
    hosts = "infra-imagemagick"
    name  = "Setup infra-imagemagick"
    tasks {
      action = "ec2_facts"
      name   = "Common | Gather EC2 facts (in order to obtain FTP pasv_address)"
    }
    tasks {
      name = "Web | Add webdev user for uploading www files"
      user = "name=webdev home=/var/www shell=/bin/bash comment='User for uploading www files' group=www-data password={{ lookup('env','FREY_FTP_PASS_ENC') }}"
    }
    tasks {
      file = "path=/var/www state=directory owner=webdev group=www-data mode=0775 recurse=yes"
      name = "Web | Create webroot"
    }
    tasks {
      apache2_module = "state=present name={{ item }}"
      name           = "Web | Apache Modules"
      register       = "apache_modules"
      with_items     = ["cgi", "perl"]
    }
    tasks {
      template = "src=templates/apache-vhosts.j2 dest=/etc/apache2/sites-enabled/000-default.conf"
      name     = "Web | Apache Vhost Default"
      register = "apache_vhost"
    }
    tasks {
      service = "name=apache2 state=restarted"
      name    = "Web | Restart"
    }
    tasks {
      template = "src=templates/vsftpd.conf.j2 dest=/etc/vsftpd.conf"
      name     = "FTP | Write config"
      register = "vsftp_conf"
    }
    tasks {
      service = "name=vsftpd state=restarted"
      name    = "FTP | Restart"
      when    = "vsftp_conf|changed"
    }
    tasks {
      cpanm      = "name={{ item }} notest=True"
      name       = "Build | Get Perl CPAN Modules"
      with_items = [
        "Image::Magick",
        "Digest::SHA3",
      ]
    }
    tasks {
      name   = "Build | Compile latest ImageMagick"
      script = "scripts/build-imagemagick.sh {{ lookup('env','FREY_IMAGEMAGICK_VERSION') }} creates=/home/ubuntu/built-imagemagick-{{ lookup('env','FREY_IMAGEMAGICK_VERSION') }}.txt"
    }
    tasks {
      copy = "src=scripts/content-fetch.sh dest=/home/ubuntu/content-fetch.sh mode=0755 owner=ubuntu group=ubuntu"
      name = "Content | Upload Daily Mirror script"
    }
    tasks {
      file = "path=/var/log/content-fetch.log state=touch owner=ubuntu group=ubuntu mode=644"
      name = "Content | Touch log of Daily Mirror script"
    }
    tasks {
      cron = "name='Daily mirror' user='ubuntu' minute='0' hour='1' job='/home/ubuntu/content-fetch.sh > /var/log/content-fetch.log 2>&1'"
      name = "Content | Setup Daily Mirror script crontab"
    }
  }
}
