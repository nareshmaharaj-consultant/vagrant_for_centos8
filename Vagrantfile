#if Vagrant::VERSION < "2.0.0"
#  $stderr.puts "Must redirect to new repository for old Vagrant versions"
#  Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
#end

NUM_WORKER_NODES=3
METRIC_NODE_ID=NUM_WORKER_NODES + 1
IP_NW="192.168.56."
IP_START=150

ALLOW_METRICS = true

Vagrant.configure("2") do |config|
  config.vm.box = "generic/centos8"
  config.vm.box_check_update = false
  config.vm.synced_folder "shared/", "/shared", create: true
  config.vm.synced_folder "data/", "/data", create: true
  config.vm.provision "shell", path: "swap.off.sh"
  config.vm.provision "shell", path: "add-fw-rules.sh"
  config.vm.provision "shell", path: "jdk11.sh"
  config.vm.provision "shell", path: "tcp_keep_alive.sh"

  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "asd0#{i}" do |node|
      node.vm.hostname = "asd0#{i}"
      node.vm.network "private_network", ip: IP_NW + "#{IP_START + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ['modifyvm', :id, '--macaddress1', "08002700005" + "#{i}"]
        vb.customize ['modifyvm', :id, '--natnet1', "10.0.5" + "#{i}.0/24"]
        vb.name = "asd0#{i}"
        vb.memory = 4096
      end
      node.vm.provision "shell", path: "install_aerospike.sh"
    end
  end

  if ALLOW_METRICS
    config.vm.define "obs0#{METRIC_NODE_ID}" do |node|
      node.vm.hostname = "obs#{METRIC_NODE_ID}"
      node.vm.network "private_network", ip: IP_NW + "#{METRIC_NODE_ID}"
      node.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ['modifyvm', :id, '--macaddress1', "08002700005" + "#{METRIC_NODE_ID}"]
        vb.customize ['modifyvm', :id, '--natnet1', "10.0.5" + "#{METRIC_NODE_ID}.0/24"]
        vb.name = "obs0#{METRIC_NODE_ID}"
        vb.memory = 4096
      end
      node.vm.provision "shell", path: "install_ams.sh"
    end
  end
end
