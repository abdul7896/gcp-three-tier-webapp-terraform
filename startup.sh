#! /bin/bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
service docker start
sudo docker run -p 8080:8080 -d gcr.io/myapplication-348521/instance-one:latest
