#!/usr/bin/env bash

setup_docker()
{
  mkdir -p /etc/docker
  tee /etc/docker/daemon.json <<-EOF
{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}
EOF
  systemctl daemon-reload
  systemctl restart docker
  docker info
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      setup_docker
      gpasswd -a ubuntu docker
      ;;
    centos)
      setup_docker
      gpasswd -a vagrant docker
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