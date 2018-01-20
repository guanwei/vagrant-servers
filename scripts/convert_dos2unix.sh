#!/usr/bin/env bash

convert_dos2unix()
{
  DIR=${1:-.}
  find $DIR -type f -print0 | xargs -0 -n 1 -P 4 dos2unix
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      apt install -y dos2unix
      convert_dos2unix /vagrant
      ;;
    centos)
      yum install -y dos2unix
      convert_dos2unix /vagrant
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