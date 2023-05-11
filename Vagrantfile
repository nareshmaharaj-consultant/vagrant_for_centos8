#if Vagrant::VERSION < "2.0.0"
#  $stderr.puts "Must redirect to new repository for old Vagrant versions"
#  Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
#end

Vagrant.configure("2") do |config|
  config.vm.box = "generic/centos8"
  config.vm.box_check_update = false
  config.vm.synced_folder "shared/", "/shared", create: true
  config.vm.synced_folder "data/", "/data", create: true
  config.vm.provision "shell", path: "swap.off.sh"
  config.vm.provision "shell", path: "add-fw-rules.sh"
  config.vm.provision "shell", path: "jdk11.sh"

  config.vm.define "m1" do |server1|
    server1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      vb.customize ['modifyvm', :id, '--macaddress1', '080027000051']
      vb.customize ['modifyvm', :id, '--natnet1', '10.0.51.0/24']
      vb.name = "m1"
      vb.memory = 4096
    end
    server1.vm.hostname = "m1.aerospike.training"
    server1.vm.network :private_network, ip: "192.168.56.151"
  end

  config.vm.define "m2" do |server2|
    server2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      vb.customize ['modifyvm', :id, '--macaddress1', '080027000052']
      vb.customize ['modifyvm', :id, '--natnet1', '10.0.52.0/24']
      vb.name = "m2"
      vb.memory = 4096
    end
    server2.vm.hostname = "m2.aerospike.training"
    server2.vm.network :private_network, ip: "192.168.56.152"
  end
end
