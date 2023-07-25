#!/bin/bash
sudo apt-get update -y 2>&1 > log.txt &&
sudo apt-get install -y apt-transport-https 2>&1 >> log.txt &&
sudo apt-get install -y ca-certificates 2>&1 >> log.txt &&
sudo apt-get install -y curl 2>&1 >> log.txt &&
sudo apt-get install -y gnupg-agent 2>&1 >> log.txt &&
sudo apt-get install -y software-properties-common 2>&1 >> log.txt &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 2>&1 >> log.txt &&
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y 2>&1 >> log.txt &&
sudo apt-get update -y 2>&1 >> log.txt &&
sudo sudo apt-get install docker-ce docker-ce-cli containerd.io -y 2>&1 >> log.txt &&
sudo usermod -aG docker ubuntu 2>&1 >> log.txt
