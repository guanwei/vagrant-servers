#!/usr/bin/env bash

change_mysql_root_password()
{
  grep -q '^skip-grant-tables' /etc/my.cnf ||
    sed -i '/\[mysqld\]/a\skip-grant-tables' /etc/my.cnf
  sed -i '/^validate_password/d' /etc/my.cnf
  systemctl restart mysqld || exit 1

  NEW_PWD=${1:-mysql}
  echo "update mysql.user set authentication_string=password('$NEW_PWD') where user='root' and host='localhost'" | mysql &&
    echo "changed mysql root password to $NEW_PWD"
  sed -i '/^skip-grant-tables/d' /etc/my.cnf
  sed -i '/\[mysqld\]/a\validate_password=off' /etc/my.cnf
  systemctl restart mysqld || exit 1
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      ;;
    centos)
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