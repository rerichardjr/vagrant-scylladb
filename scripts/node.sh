#!/bin/bash

set -euxo pipefail

# Service name for ScyllaDB
scylla_service="scylla-server"

# Folder paths for ScyllaDB
scylla_lib_folder="/var/lib/scylla"
scylla_config_folder="/etc/scylla"
some_config_folder="/etc/test"

# Configuration files for ScyllaDB
scylla_config_file="scylla.yaml"
scylla_rackdc_properties="cassandra-rackdc.properties"

# Cluster name for ScyllaDB
scylla_cluster_name="scylla_lab_cluster"

createScyllaDBConfigs() {
  
  stopScyllaDB
  #cleanScyllaDBData
  backupScyllaDBConfigs

  # initialize empty array for IP addresses
  ip_list=()
  
  for i in `seq 1 ${NODE_COUNT}`; do
    ip_list+=($NETWORK$(($NODE_START+(i - 1))))
  done
 
  # build seeds for scylla.yaml
  #scylla_seeds=$(printf "%s," "${ip_list[@]}")
  
  # remove trailing , from scylla_seeds
  #scylla_seeds=${scylla_seeds%,}

  # set node_ip to the IP in ip_list
  node_ip=${ip_list[$(($NODE_ID-1))]}

  # build cassandra-rackdc.properties
  cat > $scylla_config_folder/$scylla_rackdc_properties <<EOF
  $(
    echo "dc=datacenter1"
    echo "rack=rack$(($NODE_ID))"
  )
EOF

  #build scylla.yaml
  cat > $scylla_config_folder/$scylla_config_file <<EOF
  $(
    echo "# scylla.yaml on node $NODE_ID"
    echo "cluster_name: '${scylla_cluster_name}'"
    echo "endpoint_snitch: GossipingPropertyFileSnitch"
    echo "rpc_address: 0.0.0.0"
    echo "listen_address: ${node_ip}"
    echo "seed_provider:"
    echo "  - class_name: org.apache.cassandra.locator.SimpleSeedProvider"
    echo "    parameters:"
    echo "      - seeds: ${ip_list[0]}"
    echo "broadcast_rpc_address: ${node_ip}"
  )
EOF

  startScyllaDB

}

setupScyllaDB() {
  # uses expect script to answer questions from scylla_setup
  expect /vagrant/scripts/script.exp
}

installScyllaDB() {
  sudo gpg --homedir /tmp --no-default-keyring --keyring /etc/apt/keyrings/scylladb.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys a43e06657bac99e3
  sudo wget -O /etc/apt/sources.list.d/scylla.list https://downloads.scylladb.com/deb/debian/scylla-$SCYLLADB_VER.list
  sudo apt-get update
  sudo apt-get install -y scylla 
}

installJava() {
  sudo apt-get update
  sudo apt-get install -y openjdk-8-jre-headless
  sudo update-java-alternatives --jre-headless -s java-1.8.0-openjdk-amd64
}

startScyllaDB() {
  if ! systemctl is-active --quiet $scylla_service; then
    sudo systemctl start $scylla_service
  fi
}

stopScyllaDB() {
  if systemctl is-active --quiet "$scylla_service"; then
    sudo systemctl stop "$scylla_service"
  fi
}

cleanScyllaDBData() {
  # https://opensource.docs.scylladb.com/stable/operating-scylla/procedures/cluster-management/clear-data.html

  sudo rm -rf "$scylla_lib_folder/data"
  
  # Define an array of subdirectories to clean
  folders=("commitlog" "hints" "view_hints")
  for folder in "${folders[@]}"; do
    sudo find "$scylla_lib_folder/$folder" -type f -delete
  done
}

backupScyllaDBConfigs() {
  folders=("$scylla_config_folder" "$some_config_folder")
  for folder in "${folders[@]}"; do
    if [ ! -d $folder ]; then
      mkdir -p $folder
    fi
  done

  files=("$scylla_config_file" "$scylla_rackdc_properties")
  for file in "${files[@]}"; do
    time_stamp="$(date +%Y%m%d%H%M%S)"
    if [ -f "$scylla_config_folder/$file" ]; then
      mv "$scylla_config_folder/$file" "$scylla_config_folder/$file.$time_stamp"
    fi
  done
}

installScyllaDB
installJava
setupScyllaDB
createScyllaDBConfigs