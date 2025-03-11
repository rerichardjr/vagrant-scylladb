#!/bin/bash

set -euxo pipefail

files_folder=/vagrant/files
password_file=password.txt

updateHostsFile() {
  for i in `seq 1 ${NODE_COUNT}`; do
    host_entry="$NETWORK$(($NODE_START+(i - 1))) $NODE_HOSTNAME${i} $NODE_HOSTNAME${i}.$DOMAIN"
    if ! grep -qF "$host_entry" /etc/hosts; then
      echo "$host_entry" >> /etc/hosts
    fi
  done
}

createSupportUser() {
  if ! id ${SUPPORT_USER} >/dev/null 2>&1; then
    useradd ${SUPPORT_USER} -G sudo -m -s /bin/bash
    printf "User ${SUPPORT_USER} created."
  fi

  if [ ! -d $files_folder ]; then
    mkdir $files_folder
  fi

  if [ ! -f $files_folder/$password_file ]; then
    random_pw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8; echo)
    echo $random_pw > $files_folder/$password_file
  fi

  random_pw=$(cat $password_file)
  echo "$SUPPORT_USER:$random_pw" | chpasswd
}

installPackages() {
  sudo apt-get install -y expect
}

updateHostsFile
createSupportUser
installPackages
