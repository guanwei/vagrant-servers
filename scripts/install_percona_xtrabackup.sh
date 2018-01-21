#!/usr/bin/env bash

install_percona_xtrabackup_on_centos()
{
  if ! $(yum repolist enabled | grep -q "percona-release-.*"); then
    yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm || exit 1
  fi
  yum install -y percona-xtrabackup-24
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
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