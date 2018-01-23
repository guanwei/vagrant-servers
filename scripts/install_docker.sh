#!/usr/bin/env bash
set -e

install_docker()
{
  ## install docker using online script
  if [ ! $(command -v docker) ]; then
    sh -c "$(curl -fsSL https://get.docker.com)"
  else
    echo "docker already installed"
  fi
}

setup_docker()
{
  ## add user 'vagrant' to group 'docker'
  usermod -aG docker vagrant

  ## set docker registry mirrors
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<-EOF
{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}
EOF
  systemctl daemon-reload
  systemctl restart docker
  echo "setup docker done"

  printf "\n===== Docker Info =====\n"
  docker info
}

if [ -r /etc/os-release ]; then
  lsb_dist=$(. /etc/os-release && echo "$ID")
  case $lsb_dist in
    ubuntu)
      install_docker
      setup_docker
      ;;
    centos)
      install_docker
      setup_docker
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