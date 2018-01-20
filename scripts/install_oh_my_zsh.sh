#!/usr/bin/env bash

install_oh_my_zsh()
{
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

  grep -q "^ZSH_THEME=" ~/.zshrc &&
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/g' ~/.zshrc ||
    echo 'ZSH_THEME="agnoster"' >> ~/.zshrc

  grep -q "^DISABLE_UPDATE_PROMPT=" ~/.zshrc &&
    sed -i 's/^DISABLE_UPDATE_PROMPT=.*/DISABLE_UPDATE_PROMPT=true/g' ~/.zshrc ||
    echo 'DISABLE_UPDATE_PROMPT=true' >> ~/.zshrc

  ## install powerline fonts
  git clone https://github.com/powerline/fonts.git --depth=1
  ./fonts/install.sh
  rm -rf fonts
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      apt-get install -y zsh git
      install_oh_my_zsh
      ;;
    centos)
      yum install -y zsh git
      install_oh_my_zsh
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