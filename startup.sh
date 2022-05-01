#! /bin/bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
service docker start
sudo docker pull gcr.io/myapplication-348521/server:latest
