Staking Ethereum with Lighthouse \ Ubuntu - Mainnet
===================================================

Install Prerequisites
---------------------

Install Codecopy

https://github.com/zenorocha/codecopy#install


Update the Server
-----------------

Make sure the system is up to date with the latest software and security updates.

```
sudo apt update && sudo apt upgrade
```
```
sudo apt dist-upgrade && sudo apt autoremove
```
```
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
```
```
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

```
wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/firewall.sh
```

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
```
```
sudo apt-get remove ntp
```

Set up an Ethereum (Eth1) Node
------------------------------

An Ethereum node is required for staking. You can either run a local Eth1 node or use a third party node. This guide will provide instructions for running Go Ethereum. If you would rather use a third party option then skip this step.

Install Go Ethereum
Install the Go Ethereum client using PPA’s (Personal Package Archives).

```
sudo add-apt-repository -y ppa:ethereum/ethereum
```
```
sudo apt update
```
```
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

Paste the following service configuration into the file and save or download via wget from the link below.

```
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
```
Note:  Make sure you change to the /etc/systemd/system directory.

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/geth.service

Notable flags:
--http Expose an HTTP endpoint (http://localhost:8545) that the Lighthouse beacon chain will connect to.
--cache Size of the internal cache in GB. Reduce or increase depending on your available system memory. A setting of 2048 results in roughly 4–5GB of memory usage.
--maxpeers Maximum number of peers to connect with. More peers equals more internet data usage. Do not set this too low or your Eth1 node will struggle to stay in sync.

Reload systemd to reflect the changes and start the service. Check status to make sure it’s running correctly.

```
sudo systemctl daemon-reload
```

```
sudo systemctl start geth
```

```
sudo systemctl status geth
```

It should say active (running) in green text. If not then go back and repeat the steps to fix the problem. Press Q to quit (will not affect the geth service).

Enable the geth service to automatically start on reboot.

```
sudo systemctl enable geth
```

The Go Ethereum node will begin to sync. You can follow the progress or check for errors by running the following command. Press Ctrl+C to exit (will not affect the geth service).

```
sudo journalctl -fu geth.service
```

Check Sync Status - To check your Eth1 node sync status use the following command to access the console.

```
geth attach http://127.0.0.1:8545
```
> eth.syncing

If false is returned then your sync is complete. If syncing data is returned then you are still syncing. For reference there are roughly 700–800 million knownStates.

Download Lighthouse
-------------------
The Lighthouse client is a single binary which encapsulates the functionality of the beacon chain and validator. This step will download and prepare the Lighthouse binary.
First, go to the link below and identify the latest release. It is at the top of the page. For example:

https://github.com/sigp/lighthouse/releases

Download the archive using the commands below. Modify the URL in the instructions below to match the download link for the latest version.

```
cd ~
```

```
sudo apt install curl
```

```
curl -LO https://github.com/sigp/lighthouse/releases/download/v1.0.2/lighthouse-v1.0.2-x86_64-unknown-linux-gnu.tar.gz
```

Extract the binary from the archive and copy to the /usr/local/bin directory. The Lighthouse service will run it from there. Modify the URL name as necessary.

```
tar xvf lighthouse-v1.0.2-x86_64-unknown-linux-gnu.tar.gz
```

```
sudo cp lighthouse /usr/local/bin
```

Use the following commands to verify the binary works with your server CPU. If not, go back and download the portable version and redo the steps to here and try again.

```
cd /usr/local/bin/
```

```
./lighthouse --version # <-- should display version information
```

NOTE: There has been at least one case where version information is displayed yet subsequent commands have failed. If you get a Illegal instruction (core dumped) error while running the account validator import command (next step), then you may need to use the portable version instead.
Clean up the extracted files.

```
cd ~
```
```
sudo rm lighthouse
```
```
sudo rm lighthouse-v1.0.2-x86_64-unknown-linux-gnu.tar.gz
```

NOTE: It is necessary to follow a specific series of steps to update Lighthouse. See Appendix B — Updating Lighthouse for further information.

Import the Validator Keys
-------------------------







Download Beacon Chain systemd file

wget https://raw.githubusercontent.com/ipalvr/ethstaking_prysm_pyrmont/main/prysm-beaconchain.service
