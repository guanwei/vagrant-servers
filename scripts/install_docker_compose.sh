#!/usr/bin/env bash
set -e

install_docker_compose()
{
  # get latest docker compose released tag
  COMPOSE_VERSION=$(curl -sSk https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

  COMPOSE_TMP_PATH=/tmp/docker-compose-${COMPOSE_VERSION}
  COMPOSE_INSTALL_PATH=/usr/local/bin/docker-compose-${COMPOSE_VERSION}

  # install docker-compose
  if [ ! -f ${COMPOSE_INSTALL_PATH} ]; then
    curl -sSL https://get.daocloud.io/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` \
      -o ${COMPOSE_TMP_PATH}
    mv ${COMPOSE_TMP_PATH} ${COMPOSE_INSTALL_PATH}
    chmod +x ${COMPOSE_INSTALL_PATH}
    ln -sf ${COMPOSE_INSTALL_PATH} /usr/local/bin/docker-compose
    # Output compose version
    /usr/local/bin/docker-compose version
  else
    echo "docker-compose $COMPOSE_VERSION already installed"
  fi

  # install docker-compose command completion
  if [ ! -f /etc/bash_completion.d/docker-compose ]; then
    curl -sSL https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose \
      -o /etc/bash_completion.d/docker-compose
  fi
}

if [ -r /etc/os-release ]; then
  lsb_dist=$(. /etc/os-release && echo "$ID")
  case $lsb_dist in
    ubuntu)
      install_docker_compose
      ;;
    centos)
      install_docker_compose
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