#!/bin/bash
#Allow Go Ethereum
sudo ufw allow 30303
#Allow Lighthouse
sudo ufw allow 9000
#Allow Grafana
sudo ufw allow 3000/tcp
#Allow Prometheus
sudo ufw allow 9090/tcp
#Enable Firewall
sudo ufw enable
sudo ufw status numbered
