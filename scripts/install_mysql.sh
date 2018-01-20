#!/usr/bin/env bash

install_mysql_on_centos()
{
  if ! $(yum repolist enabled | grep -q "mysql.*-community.*"); then
    yum install -y wget
    wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    yum localinstall -y mysql57-community-release-el7-11.noarch.rpm || exit 1
    rm -f mysql57-community-release-el7-11.noarch.rpm
  fi

  if ! $(rpm -qa | grep -q "mysql-community-server"); then
    rm -f /var/log/mysqld.log
    yum install -y mysql-community-server && systemctl start mysqld || exit 1
  else
    echo "mysql-community-server is already installed"
  fi

  ## optimize mysql configuration
  echo "optimizing mysql configuration..."
  grep -q '^explicit_defaults_for_timestamp=true' /etc/my.cnf ||
    sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' /etc/my.cnf
  grep -q '^\[mysql\]' /etc/my.cnf || echo '[mysql]' >> /etc/my.cnf
  grep -q '^prompt=\\\\u@\\\\h \[\\\\d\]>\\\\_' /etc/my.cnf ||
    sed -i '/\[mysql\]/a\prompt=\\\\u@\\\\h [\\\\d]>\\\\_' /etc/my.cnf
  systemctl restart mysqld && echo "optimizing is done" || exit 1
}

change_mysql_root_password()
{
  grep -q '^skip-grant-tables' /etc/my.cnf ||
    sed -i '/\[mysqld\]/a\skip-grant-tables' /etc/my.cnf
  systemctl restart mysqld || exit 1

  NEW_PWD=${1:-Q1w2e3r4}
  mysql -uroot -e "update mysql.user set authentication_string=password('$NEW_PWD') where user='root'" &&
    echo "mysql root password changed to: $NEW_PWD"

  sed -i '/^skip-grant-tables/d' /etc/my.cnf
  systemctl restart mysqld || exit 1
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      ;;
    centos)
      install_mysql_on_centos
      change_mysql_root_password Q1w2e3r4
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