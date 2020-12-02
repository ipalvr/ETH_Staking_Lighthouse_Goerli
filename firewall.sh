#!/bin/bash
#Allow Go Ethereum
sudo ufw allow 30303
#Allow Prysm
sudo ufw allow 13000/tcp
sudo ufw allow 12000/udp
#Allow Grafana
sudo ufw allow 3000/tcp
#Allow Prometheus
sudo ufw allow 9090/tcp
#Enable Firewall
sudo ufw enable
sudo ufw status numbered
