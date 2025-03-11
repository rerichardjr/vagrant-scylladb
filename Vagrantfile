require "yaml"
settings = YAML.load_file "settings.yaml"

puts ""
puts ""
puts "\e[32m  ____             _ _       ____  ____  \e[0m"
puts "\e[32m / ___|  ___ _   _| | | __ _|  _ \\| __ ) \e[0m"
puts "\e[32m \\___ \\ / __| | | | | |/ _` | | | |  _ \\ \e[0m"
puts "\e[32m  ___) | (__| |_| | | | (_| | |_| | |_) |\e[0m"
puts "\e[32m |____/ \\___|\\__, |_|_|\\__,_|____/|____/ \e[0m"
puts "\e[32m             |___/                       \e[0m"
puts ""
puts "\e[32m github.com/rerichardjr\e[0m"
puts ""
puts ""

SCYLLADB_VER = settings["software"]["scylladb"]
NODE_COUNT = settings["nodes"]["count"]
NODE_HOSTNAME = settings["nodes"]["hostname"]
NETWORK = settings["ip"]["network"]
NODE_START = settings["ip"]["node_start"]
SUPPORT_USER = settings["support_user"]
DOMAIN = settings["ip"]["domain"]
BRIDGE = settings["bridge"]

Vagrant.configure("2") do |config|
  config.vm.box = settings["software"]["box"]
  config.vm.box_check_update = true

  (1..NODE_COUNT).each do |i|
    config.vm.define "#{NODE_HOSTNAME}#{i}" do |agent|
      ip_suffix = NODE_START + (i - 1)
      node_ip = NETWORK + "#{ip_suffix}"
      agent.vm.hostname = "#{NODE_HOSTNAME}#{i}"
      agent.vm.network :public_network, ip: "#{node_ip}", :bridge => BRIDGE
      agent.vm.provider "virtualbox" do |vb|
        vb.cpus = settings["nodes"]["cpu"]
        vb.memory = settings["nodes"]["memory"]
      end
      agent.vm.disk :disk, name: "scylladb_disk", size: "20GB"

      agent.vm.provision "shell",
        name: "Configure common settings for nodes",
        env: {
          "SUPPORT_USER" => SUPPORT_USER,
          "DOMAIN" => DOMAIN,
          "NODE_COUNT" => NODE_COUNT,
          "NETWORK" => NETWORK,
          "NODE_START" => NODE_START,
          "NODE_HOSTNAME" => NODE_HOSTNAME,
        },
        path: "scripts/common.sh"

      agent.vm.provision "shell",
        name: "Configure scylladb nodes",
        env: {
            "SCYLLADB_VER" => SCYLLADB_VER,
            "NETWORK" => NETWORK,
            "NODE_COUNT" => NODE_COUNT,
            "NODE_ID" => "#{i}",
            "NODE_START" => NODE_START,
        },
        path: "scripts/node.sh"
    end
  end
end
