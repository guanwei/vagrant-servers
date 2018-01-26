#!/usr/bin/env bash
set -e

optimize_mysql_configuration()
{
  CONF_FILE=${1:-/etc/my.cnf}

  ## optimize mysql configuration
  echo "optimizing mysql configuration..."
  grep -q '^\[mysqld\]' $CONF_FILE || printf '\n[mysqld]\n' >> $CONF_FILE
  grep -q '^validate_password_policy=' $CONF_FILE &&
    sed -i 's/^validate_password_policy=.*/validate_password_policy=LOW/g' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\validate_password_policy=LOW' $CONF_FILE
  grep -q '^plugin-load-add=validate_password.so' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\plugin-load-add=validate_password.so' $CONF_FILE
  grep -q '^explicit_defaults_for_timestamp=' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' $CONF_FILE
  grep -q '^log-bin=' $CONF_FILE || (
    mkdir -p /var/log/mysql && chown -R mysql:mysql $CONF_FILE
    sed -i '/\[mysqld\]/a\log-bin=/var/log/mysql/mysql-bin.log' $CONF_FILE
  )
  grep -q '^max_binlog_size=' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\max_binlog_size=100M' $CONF_FILE
  grep -q '^expire_logs_days=' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\expire_logs_days=10' $CONF_FILE
  grep -q '^server-id=' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\server-id=1' $CONF_FILE
  grep -q '^\[mysql\]' $CONF_FILE || printf '\n[mysql]\n' >> $CONF_FILE
  grep -q '^prompt=' $CONF_FILE ||
    sed -i '/\[mysql\]/a\prompt=\\\\u@\\\\h [\\\\d]>\\\\_' $CONF_FILE
  echo "optimizing is done, restart mysql to effect"
}

install_mysql_on_ubuntu()
{
  ## export DEBIAN_FRONTEND=noninteractive

#debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select mysql-5.7'
#debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-tools select '
#debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-preview select '
#debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-product select Ok'
#wget https://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
#dpkg -i mysql-apt-config_0.8.9-1_all.deb
#apt-get update
#apt-get install -y mysql-server-5.7

  if [ "$(dpkg -l | grep 'mysql-server-5.7')" = "" ]; then
    # Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
    PWD=${1:-mysql}
    echo "mysql-server-5.7 mysql-server/root_password password $PWD" | debconf-set-selections
    echo "mysql-server-5.7 mysql-server/root_password_again password $PWD" | debconf-set-selections
    apt-get install -y mysql-server-5.7
    echo "mysql root password is $PWD"

    optimize_mysql_configuration /etc/mysql/my.cnf
    systemctl restart mysql
  else
    echo "mysql-server-5.7 already installed"
  fi
}

install_mysql_on_centos()
{
  if [ "$(yum repolist enabled | grep 'mysql57-community')" = "" ]; then
    yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
  fi

  if [ "$(rpm -qa | grep 'mysql-community-server')" = "" ]; then
    rm -f /var/log/mysqld.log
    yum install -y mysql-community-server
    systemctl restart mysqld

    optimize_mysql_configuration /etc/my.cnf
    systemctl restart mysqld

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