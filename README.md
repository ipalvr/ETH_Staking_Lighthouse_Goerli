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

Create and run this script or download via wget.

```
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
```
Note: Geth node Port 8545wget firewall.sh

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/firewall.sh

Configure Timekeeping
---------------------

Ubuntu has time synchronization built in and activated by default using systemd’s timesyncd service. Verify it’s running correctly.

```
timedatectl
```

The NTP service should be active. If not then run:

```
sudo timedatectl set-ntp on
```

You should only be using a single keeping service. If you were using NTPD from a previous installation you can check if it exists and remove it using the following commands.

```
ntpq -p
sudo apt-get remove ntp
```

Set up an Ethereum (Eth1) Node
------------------------------

An Ethereum node is required for staking. You can either run a local Eth1 node or use a third party node. This guide will provide instructions for running Go Ethereum. If you would rather use a third party option then skip this step.

Install Go Ethereum
Install the Go Ethereum client using PPA’s (Personal Package Archives).

```
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt update
sudo apt install geth
```

Go Ethereum will be configured to run as a background service. Create an account for the service to run under. This type of account can’t log into the server.

```
sudo useradd --no-create-home --shell /bin/false goeth
```

Create the data directory for the Eth1 chain. This is required for storing the Eth1 node data.

```
sudo mkdir -p /var/lib/goethereum
```

Set directory permissions. The goeth account needs permission to modify the data directory.

```
sudo chown -R goeth:goeth /var/lib/goethereum
```

Create a systemd service config file to configure the service.

```
sudo nano /etc/systemd/system/geth.service
```

Paste the following service configuration into the file.

[Unit]
Description=Go Ethereum Client
After=network.target
Wants=network.target
[Service]
User=goeth
Group=goeth
Type=simple
Restart=always
RestartSec=5
ExecStart=geth --http --datadir /var/lib/goethereum --cache 2048 --maxpeers 30
[Install]
WantedBy=default.target

Notable flags:
--http Expose an HTTP endpoint (http://localhost:8545) that the Lighthouse beacon chain will connect to.
--cache Size of the internal cache in GB. Reduce or increase depending on your available system memory. A setting of 2048 results in roughly 4–5GB of memory usage.
--maxpeers Maximum number of peers to connect with. More peers equals more internet data usage. Do not set this too low or your Eth1 node will struggle to stay in sync.
Check the screen shot below for reference. Press CTRL+C then ‘y’ then <enter> to save and exit.







Download Beacon Chain systemd file

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/prysm-beaconchain.service
