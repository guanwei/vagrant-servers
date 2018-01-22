# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  required_plugins = %w(vagrant-vbguest vagrant-timezone vagrant-proxyconf)
  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if not plugins_to_install.empty?
    puts "Installing plugins: #{plugins_to_install.join(' ')}"
    if system "vagrant plugin install #{plugins_to_install.join(' ')}"
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort "Installation of one or more plugins has failed. Aborting."
    end
  end

  config.timezone.value = :host
  
  if ENV["http_proxy"]
    config.proxy.http = ENV["http_proxy"]
  end
  if ENV["https_proxy"]
    config.proxy.https = ENV["https_proxy"]
  end
  if ENV["no_proxy"]
    config.proxy.no_proxy = ENV["no_proxy"]
  end

  config.vm.box_check_update = false
  config.vbguest.auto_update = false
  config.ssh.forward_x11 = true

  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      mkdir -p /root/.ssh
      echo #{ssh_pub_key} > /root/.ssh/authorized_keys
    SHELL
  end

  config.vm.provision "docker" do |d|
    d.post_install_provision "shell", path: "scripts/setup_docker.sh"
  end
  config.vm.provision "shell", path: "scripts/install_docker_compose.sh"
  config.vm.provision "shell", path: "scripts/install_oh_my_zsh.sh"
  config.vm.provision "shell", path: "scripts/convert_dos2unix.sh"

  config.vm.define "ubuntu16", autostart: false do |host|
    host.vm.box = "bento/ubuntu-16.04"
    host.vm.hostname = "ubuntu16"
    host.vm.network "private_network", ip: "192.168.33.10"
    host.vm.provider "virtualbox" do |vb|
      vb.name = "ubuntu16"
      vb.cpus = "1"
      vb.memory = "1024"
    end
    host.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get upgrade -y
      apt-get autoremove -y
    SHELL
  end

  config.vm.define "centos7", autostart: false do |host|
    host.vm.box = "bento/centos-7"
    host.vm.hostname = "centos7"
    host.vm.network "private_network", ip: "192.168.33.11"
    host.vm.provider "virtualbox" do |vb|
      vb.name = "centos7"
      vb.cpus = "1"
      vb.memory = "1024"
    end
    host.vm.provision "shell", inline: <<-SHELL
      yum update -y
    SHELL
  end
  
  config.vm.define "rhel7", autostart: false do |host|
    host.vm.box = "generic/rhel7"
    host.vm.hostname = "rhel7"
    host.vm.network "private_network", ip: "192.168.33.12"
    host.vm.provider "virtualbox" do |vb|
      vb.name = "rhel7"
      vb.cpus = "1"
      vb.memory = "1024"
    end
    host.vm.provision "shell", inline: <<-SHELL
      yum update -y
    SHELL
  end
end