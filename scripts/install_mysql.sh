#!/usr/bin/env bash

install_mysql_on_centos()
{
  if ! $(yum repolist enabled | grep -q "mysql.*-community.*"); then
    yum install https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm || exit 1
  fi

  if ! $(rpm -qa | grep -q "mysql-community-server"); then
    rm -f /var/log/mysqld.log
    yum install -y mysql-community-server && systemctl restart mysqld || exit 1

    ## optimize mysql configuration
    echo "optimizing mysql configuration..."
    grep -q '^validate_password=' /etc/my.cnf &&
      sed -i 's/^validate_password=.*/validate_password=off/g' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\validate_password=off' /etc/my.cnf
    grep -q '^explicit_defaults_for_timestamp=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' /etc/my.cnf
    grep -q '^log-bin=' /etc/my.cnf || (
      mkdir -p /var/log/mysql
      chown -R mysql:mysql /var/log/mysql
      sed -i '/\[mysqld\]/a\log-bin=/var/log/mysql/mysql-bin' /etc/my.cnf
    )
    grep -q '^expire_logs_days=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\expire_logs_days=7' /etc/my.cnf
    grep -q '^server-id=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\server-id=1' /etc/my.cnf
    grep -q '^\[mysql\]' /etc/my.cnf || echo -e '\n[mysql]' >> /etc/my.cnf
    grep -q '^prompt=' /etc/my.cnf ||
      sed -i '/\[mysql\]/a\prompt=\\\\u@\\\\h [\\\\d]>\\\\_' /etc/my.cnf
    systemctl restart mysqld && echo "optimizing is done" || exit 1

    OLD_PWD=$(grep 'A temporary password' /var/log/mysqld.log | awk '{print $NF}')
    if [[ -n $OLD_PWD ]]; then
      echo "mysql root temporary password is $OLD_PWD"
      NEW_PWD=${1:-mysql}
      mysqladmin -uroot -p$OLD_PWD password "$NEW_PWD" &&
        echo "changed mysql root password to $NEW_PWD"
    else
      echo "mysql root temporary password not found"
    fi
    
  else
    echo "mysql-community-server already installed"
  fi
}

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      ;;
    centos)
      install_mysql_on_centos Q1w2e3r4
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