#!/usr/bin/env bash
set -e

optimize_mysql_configuration()
{
  CONF_FILE=${1:-/etc/my.cnf}

  ## optimize mysql configuration
  echo "optimizing mysql configuration..."
  grep -q '^\[mysqld\]' $CONF_FILE || printf '\n[mysqld]\n' >> $CONF_FILE
  grep -q '^bind-address=' $CONF_FILE &&
    sed -i 's/^bind-address=.*/bind-address=0\.0\.0\.0/g' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\bind-address=0\.0\.0\.0' $CONF_FILE
  grep -q '^validate_password_policy=' $CONF_FILE &&
    sed -i 's/^validate_password_policy=.*/validate_password_policy=LOW/g' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\validate_password_policy=LOW' $CONF_FILE
  grep -q '^plugin-load-add=validate_password.so' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\plugin-load-add=validate_password.so' $CONF_FILE
  grep -q '^explicit_defaults_for_timestamp=' $CONF_FILE ||
    sed -i '/\[mysqld\]/a\explicit_defaults_for_timestamp=true' $CONF_FILE
  grep -q '^log-bin=' $CONF_FILE || (
    mkdir -p /var/log/mysql && chown -R mysql:mysql /var/log/mysql
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
  echo "optimizing is done, restart mysql server to effect"
}

install_mysql_on_ubuntu()
{
  if [ "$(dpkg -l | grep 'mysql-apt-config')" = "" ]; then
    # install mysql apt repository
    echo "mysql-apt-config mysql-apt-config/select-product select Ok" | debconf-set-selections
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
    DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.9-1_all.deb
    rm -f mysql-apt-config_0.8.9-1_all.deb
  fi

  if [ "$(dpkg -l | grep 'mysql-community-server')" = "" ]; then
    # install MySQL Server in a Non-Interactive mode. Default root password will be "mysql"
    PWD=${1:-mysql}
    echo "mysql-community-server mysql-community-server/root-pass password $PWD" | debconf-set-selections
    echo "mysql-community-server mysql-community-server/re-root-pass password $PWD" | debconf-set-selections
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-community-server
    echo "mysql root password is $PWD"

    optimize_mysql_configuration /etc/mysql/my.cnf
    systemctl restart mysql && echo "mysql server restarted"
  else
    echo "mysql-community-server already installed"
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
    systemctl restart mysqld && echo "mysql server restarted"

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