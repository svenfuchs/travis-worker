# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # config.vm.box = 'ubuntu-12.10-quantal'
  config.vm.box = 'ubuntu-13.04-raring'
  config.vm.box_url = 'https://s3.amazonaws.com/life360-vagrant/raring64.box'
  # config.vm.box_url = 'http://cloud-images.ubuntu.com/raring/current/raring-server-cloudimg-vagrant-amd64-disk1.box'

  config.vm.network :forwarded_port, guest: 22, host: 22

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  config.ssh.forward_agent = true

  config.vm.synced_folder '.', '/home/travis/travis-worker'

  # config.vm.provider :virtualbox do |vm|
  #   vm.customize ["modifyvm", :id, "--memory", "6144"]
  # end

  config.vm.provider :vmware_fusion do |vm|
    # vm.vmx['memsize'] = '6144'
    vm.vmx['memsize'] = '1024'
  end

  # config.cache.auto_detect = true
  # config.cache.enable :apt
  # config.cache.enable :gem

  # config.cache.enable_nfs  = true
end

