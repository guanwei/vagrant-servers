#!/usr/bin/env bash
set -e

install_percona_xtrabackup_on_ubuntu()
{
  if [ "$(dpkg -l | grep 'percona-release')" = "" ]; then
    apt-get install -y wget
    wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
    rm -f percona-release_0.1-4.$(lsb_release -sc)_all.deb
    apt-get update
  fi
  apt-get install -y percona-xtrabackup-24
  hash -r
}

install_percona_xtrabackup_on_centos()
{
  if [ "$(yum repolist enabled | grep 'percona-release')" = "" ]; then
    yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
  fi
  yum install -y percona-xtrabackup-24
  hash -r
}

if [ -r /etc/os-release ]; then
  lsb_dist=$(. /etc/os-release && echo "$ID")
  case $lsb_dist in
    ubuntu)
      install_percona_xtrabackup_on_ubuntu
      ;;
    centos)
      install_percona_xtrabackup_on_centos
      ;;
  *)
    echo "your system must be ubuntu/centos"
    exit 1
    ;;
  esac
else
  echo "'/etc/os-release' file is not available"
  exit 1
fi