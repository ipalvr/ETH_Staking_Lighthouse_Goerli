Staking Ethereum with Lighthouse \ Ubuntu
=========================================

Update the Server
-----------------

Make sure the system is up to date with the latest software and security updates.

```
sudo apt update && sudo apt upgrade
sudo apt dist-upgrade && sudo apt autoremove
sudo reboot
```

Download firewall.sh

wget https://raw.githubusercontent.com/Weibeler/ethstaking_prysm_pyrmont/main/firewall.sh

Download Beacon Chain systemd file

wget https://raw.githubusercontent.com/Weibeler/ethstaking_prysm_pyrmont/main/prysm-beaconchain.service
