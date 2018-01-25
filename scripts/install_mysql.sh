#!/usr/bin/env bash
set -e

install_mysql_on_ubuntu()
{
  # Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
  PWD=${1:-mysql}
  echo "mysql-server-5.7 mysql-server/root_password password $PWD" | debconf-set-selections
  echo "mysql-server-5.7 mysql-server/root_password_again password $PWD" | debconf-set-selections
  apt-get install -y mysql-server-5.7
  echo "mysql root password is $PWD"

  ## optimize mysql configuration
  echo "optimizing mysql configuration..."
  grep -q '^\[mysqld\]' /etc/mysql/my.cnf || printf '\n[mysqld]\n' >> /etc/mysql/my.cnf
  grep -q '^explicit_defaults_for_timestamp=' /etc/mysql/my.cnf ||
    sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' /etc/mysql/my.cnf
  grep -q '^log-bin=' /etc/mysql/my.cnf || (
    mkdir -p /var/log/mysql
    chown -R mysql:mysql /var/log/mysql
    sed -i '/\[mysqld\]/a\log-bin=/var/log/mysql/mysql-bin.log' /etc/mysql/my.cnf
  )
  grep -q '^server-id=' /etc/mysql/my.cnf ||
    sed -i '/\[mysqld\]/a\server-id=1' /etc/mysql/my.cnf
  grep -q '^\[mysql\]' /etc/mysql/my.cnf || printf '\n[mysql]\n' >> /etc/mysql/my.cnf
  grep -q '^prompt=' /etc/mysql/my.cnf ||
    sed -i '/\[mysql\]/a\prompt=\\\\u@\\\\h [\\\\d]>\\\\_' /etc/mysql/my.cnf
  systemctl restart mysql
  echo "optimizing is done"
}

install_mysql_on_centos()
{
  if [ ! $(yum repolist enabled | grep -q "mysql.*-community.*") ]; then
    yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
  fi

  if [ ! $(rpm -qa | grep -q "mysql-community-server") ]; then
    rm -f /var/log/mysqld.log
    yum install -y mysql-community-server
    systemctl restart mysqld

    ## optimize mysql configuration
    echo "optimizing mysql configuration..."
    grep -q '^\[mysqld\]' /etc/my.cnf || printf '\n[mysqld]\n' >> /etc/my.cnf
    grep -q '^validate_password=' /etc/my.cnf &&
      sed -i 's/^validate_password=.*/validate_password=off/g' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\validate_password=off' /etc/my.cnf
    grep -q '^explicit_defaults_for_timestamp=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' /etc/my.cnf
    grep -q '^log-bin=' /etc/my.cnf || (
      mkdir -p /var/log/mysql
      chown -R mysql:mysql /var/log/mysql
      sed -i '/\[mysqld\]/a\log-bin=/var/log/mysql/mysql-bin.log' /etc/my.cnf
    )
    grep -q '^max_binlog_size=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\max_binlog_size=100M' /etc/my.cnf
    grep -q '^expire_logs_days=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\expire_logs_days=10' /etc/my.cnf
    grep -q '^server-id=' /etc/my.cnf ||
      sed -i '/\[mysqld\]/a\server-id=1' /etc/my.cnf
    grep -q '^\[mysql\]' /etc/my.cnf || printf '\n[mysql]\n' >> /etc/my.cnf
    grep -q '^prompt=' /etc/my.cnf ||
      sed -i '/\[mysql\]/a\prompt=\\\\u@\\\\h [\\\\d]>\\\\_' /etc/my.cnf
    systemctl restart mysqld
    echo "optimizing is done"

    OLD_PWD=$(grep 'A temporary password' /var/log/mysqld.log | awk '{print $NF}')
    if [ -n $OLD_PWD ]; then
      echo "mysql root temporary password is $OLD_PWD"
      NEW_PWD=${1:-mysql}
      mysqladmin -uroot -p$OLD_PWD password "$NEW_PWD"
      echo "mysql root password changed to $NEW_PWD"
    else
      echo "mysql root temporary password not found"
    fi
  else
    echo "mysql-community-server already installed"
  fi
}

if [ -r /etc/os-release ]; then
  lsb_dist=$(. /etc/os-release && echo "$ID")
  case $lsb_dist in
    ubuntu)
      install_mysql_on_ubuntu Q1w2e3r4
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