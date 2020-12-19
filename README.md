Staking Ethereum with Lighthouse \ Ubuntu - Mainnet
===================================================

Update the Server
-----------------

Make sure the system is up to date with the latest software and security updates.

```
sudo apt update && sudo apt upgrade
sudo apt dist-upgrade && sudo apt autoremove
sudo reboot
```
Secure the Server
-----------------

Find your available port.

```
sudo ss -tulpn | grep ':<yourSSHportnumber>'
```
  
Update the firewall to allow inbound traffic on <yourSSHportnumber>. SSH requires TCP.

```
sudo ufw allow <yourSSHportnumber>/tcp
```
  
Next change the default SSH port.

```
sudo nano /etc/ssh/sshd_config
```

Find the line with # Port 22 or Port 22 and change it to Port <yourSSHportnumber>. Remove the # if it was present.
Restart the SSH service.
  
```  
sudo systemctl restart ssh
```

Next time you log in via SSH use <yourSSHportnumber> for the port.
Optional: If you were already using UFW with port 22/TCP allowed then update the firewall to deny inbound traffic on that port. Only do this after you log in using the new SSH port.

```
sudo ufw deny 22/tcp
```

Install UFW
UFW should be installed by default. The following command will ensure it is.

```
sudo apt install ufw
```

Apply UFW Defaults
Explicitly apply the defaults. Inbound traffic denied, outbound traffic allowed.

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Download firewall.sh

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/firewall.sh

Download Beacon Chain systemd file

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/prysm-beaconchain.service
