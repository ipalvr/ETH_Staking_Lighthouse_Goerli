<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Staking Ethereum with Lighthouse \ Ubuntu - Mainnet](#staking-ethereum-with-lighthouse-%5C-ubuntu---mainnet)
  - [Install Prerequisites](#install-prerequisites)
  - [Update the Server](#update-the-server)
  - [Secure the Server](#secure-the-server)
  - [Configure Timekeeping](#configure-timekeeping)
  - [Set up an Ethereum (Eth1) Node](#set-up-an-ethereum-eth1-node)
  - [Download Lighthouse](#download-lighthouse)
  - [Import the Validator Keys](#import-the-validator-keys)
- [Configure the Beacon Node Service](#configure-the-beacon-node-service)
  - [Create and Configure the Service](#create-and-configure-the-service)
- [Configure the Validator Service](#configure-the-validator-service)
  - [Set up the Validator Node Account and Directory](#set-up-the-validator-node-account-and-directory)
  - [Create and Configure the Service](#create-and-configure-the-service-1)
- [Updating Geth](#updating-geth)
- [Updating Lighthouse](#updating-lighthouse)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

Staking Ethereum with Lighthouse \ Ubuntu - Mainnet
===================================================

Update the Server
-----------------

Make sure the system is up to date with the latest software and security updates.

```
sudo apt update && sudo apt upgrade -y
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
sudo ss -tulpn | grep ':<yourdesiredSSHportnumber>'
```
  
Update the firewall to allow inbound traffic on <yourSSHportnumber>. SSH requires TCP.

```
sudo ufw allow <yourdesiredSSHportnumber>/tcp
```
  
Next change the default SSH port.

```
sudo vim /etc/ssh/sshd_config
```

Find the line with # Port 22 or Port 22 and change it to Port <yourdesiredSSHportnumber>. Remove the # if it was present and save the file.
Restart the SSH service.
  
```  
sudo systemctl restart ssh
```

Next time you log in via SSH use <yourdesiredSSHportnumber> for the port.
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

Create and run this script or download via wget.  (Need to revise)

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
Note: Geth node Port 8545

```
wget https://github.com/ipalvr/ETH_Staking_Lighthouse_Goerli/blob/e46fafcc6634945fb3544aa74ab0707255617424/firewall.sh
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

Mount USB
------------------------------

Add the Universe Repository
```
sudo add-apt-repository universe
```
Check the filesystem name
```
lsblk -f
```
Install exfat utilities
```
sudo apt-get install exfat-fuse exfat-utils
```
Make a mount point
```
sudo mkdir /media/usb
```
Mounts and grant access to the 1000 user, in this case ubuntu
```
sudo mount -o uid=1000,gid=1000 /dev/sda1 /media/usb
```
Get UUID to permanently mount drive
```
sudo blkid
```
Edit fstab
```
sudo vim /etc/fstab
```
```
UUID=6307-9516 /media/usb auto uid=1000,gid=1000,umask=022,nosuid,nodev,nofail,x-gvfs-show 0 0
```

At the bottom of that file, add an entry that contains the UUID:

Details:
UUID=CEE8-AC73 - is the UUID of the drive. You don't have to use the UUID here. You could just use /dev/sdj, but it's always safer to use the UUID as that will never change (whereas the device name could).
/data - is the mount point for the device.
auto - automatically mounts the partition at boot 
nosuid - specifies that the filesystem cannot contain set userid files. This prevents root escalation and other security issues.
nodev - specifies that the filesystem cannot contain special devices (to prevent access to random device hardware).
nofail - removes the errorcheck.
x-gvfs-show - show the mount option in the file manager. If this is on a GUI-less server, this option won't be necessary.
0 - determines which filesystems need to be dumped (0 is the default).
0 - determine the order in which filesystem checks are done at boot time (0 is the default).


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
cd /media/usb
```
```
mkdir bin && cd bin
```
```
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.0.0/lighthouse-v3.0.0-aarch64-unknown-linux-gnu.tar.gz
```

Extract the binary from the archive.  The Lighthouse service will run it from there. Modify the URL name as necessary.

```
tar xvf lighthouse-v2.5.1-aarch64-unknown-linux-gnu.tar.gz
```
```
rm lighthouse-v2.5.1-aarch64-unknown-linux-gnu.tar.gz
```

Use the following commands to verify the binary works with your server CPU. If not, go back and download the portable version and redo the steps to here and try again.

```
./lighthouse --version 
```

NOTE: There has been at least one case where version information is displayed yet subsequent commands have failed. If you get a Illegal instruction (core dumped) error while running the account validator import command (next step), then you may need to use the portable version instead.
Clean up the extracted files.

NOTE: It is necessary to follow a specific series of steps to update Lighthouse. See Appendix B — Updating Lighthouse for further information.

Import the Validator Keys
-------------------------

Configure Lighthouse by importing the validator keys and creating the service and service configuration required to run it.

Copy the Validator Keystore Files

If you generated the validator keystore-m…json file(s) on a machine other than your Ubuntu server you will need to copy the file(s) over to your home directory. You can do this using a USB drive (if your server is local), or via secure FTP (SFTP).

Place the files here: $HOME/eth2deposit-cli/validator_keys  Create the directories if necessary.

Import Keystore Files into the Validator Wallet

Create a directory to store the validator wallet data and give the current user permission to access it. The current user needs access because they will be performing the import. Change <yourusername> to the logged in username.

```
sudo mkdir -p /media/usb/lighthouse
```
```
cd  /media/usb/lighthouse
```
sudo chown -R <yourusername>:<yourusername> /media/usb/lighthouse
```

Copy key(s) via scp - keystore-m_xxxxx_xxxx_x_x_x-xxxxxxxxxxx.json
```
scp -P <YourPort> keystore-m_xxxxxxxxx.json username@x.x.x.x:eth2deposit-cli/validator_keys
```

Run the validator key import process. You will need to provide the directory where the generated keystore-m files are located. E.g. $HOME/eth2deposit-cli/validator_keys.

```
cd /media/usb/bin
```
```
./lighthouse --network goerli account validator import --directory ~/eth2deposit-cli/validator_keys --datadir /media/usb/lighthouse
```

You will be asked to provide the password for the validator keys. This is the password you set when you created the keys during Step 1.

You will be asked to provide the password for each key, one-by-one. Be sure to correctly provide the password each time because the validator will be running as a service and it needs to persist the password(s) to a file to access the key(s).

Note that the validator data is saved in the following location created during the keystore import process: /var/lib/lighthouse/validators.

Restore default permissions to the lighthouse directory. (Will return Operation Not Permitted because of filesystem on USB drive.  Not to worry for Goerli.)

```
sudo chown -R root:root /media/usb/lighthouse
```

Configure Swap Space
====================

A swap space (a file on the disk used to store in-memory data when the system memory gets low) is used to guard against out-of-memory errors. It is particularly useful for clients that require large amounts of memory when syncing or running.

```
free -h
```

Zeros on the Swap: row indicate there is no swap space assigned

Recommended Swap Space

RAM     Swap Size
  8GB           3GB
 12GB           3GB
 16GB           4GB
 24GB           5GB
 32GB           6GB
 64GB           8GB
128GB          11GB

Check for Space

```
df -h
```

Create the swap space.

```
sudo fallocate -l 3G /swapfile
```
```
sudo chmod 600 /swapfile
```
```
sudo mkswap /swapfile
```
```
sudo swapon /swapfile
```

Verify the changes.

```
free -h
```

Enable the swap space to persist after reboot.

```
sudo cp /etc/fstab /etc/fstab.bak
```
```
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Configure the swap space.

```
sudo sysctl vm.swappiness=10
```
```
sudo sysctl vm.vfs_cache_pressure=50
```

Open the config file to configure the swap space.

```
sudo vim /etc/sysctl.conf
```

Add the following to the end of the file.

```
vm.swappiness=10
vm.vfs_cache_pressure = 50
```
The swap file is now configured. Monitor using the htop command.

Configure the Beacon Node Service
=================================

In this step you will configure and run the Lighthouse beacon node as a service so if the system restarts the process will automatically start back up again.

Set up the Beacon Node Account and Directory

Create an account for the beacon node to run under. This type of account can’t log into the server.

```
sudo useradd --no-create-home --shell /bin/false lighthousebeacon
```
Create the data directory for the Lighthouse beacon node database and set permissions.
```
sudo mkdir -p /media/usb/lighthouse/beacon
```
```
sudo chown -R lighthousebeacon:lighthousebeacon /media/usb/lighthouse/beacon
```
```
sudo chmod 700 /var/lib/lighthouse/beacon
```
```
ls -dl /var/lib/lighthouse/beacon
```

Create and Configure the Service
--------------------------------

Create a systemd service config file to configure the service.

```
sudo nano /etc/systemd/system/lighthousebeacon.service
```
Paste the following into the file.
```
[Unit]
Description=Lighthouse Eth2 Client Beacon Node
Wants=network-online.target
After=network-online.target
[Service]
User=lighthousebeacon
Group=lighthousebeacon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse bn --network mainnet --datadir /var/lib/lighthouse --staking --eth1-endpoints http://127.0.0.1:8545,https://eth-mainnet.alchemyapi.io/v2/yourAPIkey,https://mainnet.infura.io/v3/yourAPIkey
[Install]
WantedBy=multi-user.target
```

Notable flags
bn subcommand instructs the lighthouse binary to run a beacon node.
--eth1-endpoints One or more comma-delimited server endpoints for web3 connection. If multiple endpoints are given the endpoints are used as fallback in the given order. Also enables the -- eth1 flag. E.g. --eth1-endpoints http://127.0.0.1:8545,https://yourinfuranode,https://your3rdpartynode.

Reload systemd to reflect the changes and start the service.

```
sudo systemctl daemon-reload
```
Note: If you are running a local Eth1 node (see Step 6) you should wait until it fully syncs before starting the lighthousebeacon service. Check progress here: sudo journalctl -fu geth.service
Start the service and check to make sure it’s running correctly.
```
sudo systemctl start lighthousebeacon
```
```
sudo systemctl status lighthousebeacon
```

Enable the service to automatically start on reboot.
```
sudo systemctl enable lighthousebeacon
```
If the Eth2 chain is post-genesis the Lighthouse beacon chain will begin to sync. It may take several hours to fully sync. You can follow the progress or check for errors by running the journalctl command. Press CTRL+C to exit (will not affect the lighthousebeacon service).
```
sudo journalctl -fu lighthousebeacon.service
```
A truncated view of the log shows the following status information.

[NOTE: A current issue is resulting in an incorrect error message.]

INFO Waiting for genesis 

wait_time: 5 days 5 hrs, peers: 50, service: slot_notifier

Once the Eth2 mainnet starts up the beacon chain will automatically start processing. The output will give an indication of time to fully sync with the Eth1 node.

Configure the Validator Service
===============================

In this step you will configure and run the Lighthouse validator node as a service so if the system restarts the process will automatically start back up again.

Set up the Validator Node Account and Directory
-----------------------------------------------

Create an account for the validator node to run under. This type of account can’t log into the server.
```
sudo useradd --no-create-home --shell /bin/false lighthousevalidator
```
In the validator wallet creation process we created the following directory: /var/lib/lighthouse/validators. Set directory permissions so the lighthousevalidator account can modify that directory.
```
sudo chown -R lighthousevalidator:lighthousevalidator /var/lib/lighthouse/validators
```
```
sudo chmod 700 /var/lib/lighthouse/validators
```
```
ls -dl /var/lib/lighthouse/validators
```

Create and Configure the Service
--------------------------------

Create a systemd service file to store the service config.
```
sudo nano /etc/systemd/system/lighthousevalidator.service
```

Paste the following into the file.

```
[Unit]
Description=Lighthouse Eth2 Client Validator Node
Wants=network-online.target
After=network-online.target
#BindsTo=lighthousebeacon.service  Removed 11/30/2020 per Somer
[Service]
User=lighthousevalidator
Group=lighthousevalidator
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse vc --network mainnet --datadir /var/lib/lighthouse --graffiti "Hello from ipalvr!"
[Install]
WantedBy=multi-user.target
```

Notable flags.
BindsTo=lighthousebeacon.service will stop the validator service if the beacon service stops. The validator service cannot function without the beacon service.

vc subcommand instructs the lighthouse binary to run a validator node.

--graffiti "<yourgraffiti>" Replace with your own graffiti string. For security and privacy reasons avoid information that can uniquely identify you. E.g. --graffiti "Hello Eth2! From Dominator".

Reload systemd to reflect the changes and start the service and check to make sure it’s running correctly.
```
sudo systemctl daemon-reload
```
```
sudo systemctl start lighthousevalidator
```
```
sudo systemctl status lighthousevalidator
```

Enable the service to automatically start on reboot.
```
sudo systemctl enable lighthousevalidator
```

You can follow the progress or check for errors by running the journalctl command. Press CTRL+C to exit (will not affect the lighthousevalidator service.)
```
sudo journalctl -fu lighthousevalidator.service
```

For post-genesis deposits it may take hours or even days to activate the validator account(s) once the beacon chain has started processing.
Once the Eth2 mainnet starts up the beacon chain and validator will automatically start processing.

Once the Eth2 mainnet starts up the beacon chain and validator will automatically start processing.

Updating Geth
=============

If you need to update to the latest version of Geth follow these steps.
```
sudo systemctl stop lighthousevalidator
```
```
sudo systemctl stop lighthousebeacon
```
```
sudo systemctl stop geth
```
```
sudo apt update && sudo apt upgrade
```
```
sudo systemctl start geth
```
```
sudo systemctl status geth # <-- Check for errors
```
```
sudo journalctl -fu geth # <-- Monitor
```
```
sudo systemctl start lighthousebeacon
```
```
$ sudo systemctl status lighthousebeacon # <-- Check for errors
```
```
sudo journalctl -fu lighthousebeacon # <-- Monitor
```
```
sudo systemctl start lighthousevalidator
```
```
sudo systemctl status lighthousevalidator # <-- Check for errors
```
```
sudo journalctl -fu lighthousevalidator # <-- Monitor
```

Updating Lighthouse
===================

If you need to update to the latest version of Lighthouse follow these steps.

First, go here and identify the latest Linux release. Modify the URL in the instructions below to match the download link for the latest version.

NOTE: There are two types of binaries — portable and non-portable.  The -portable suffix which indicates if the portable feature is used:
Without portable: uses modern CPU instructions to provide the fastest signature verification times (may cause Illegal instruction error on older CPUs)
With portable: approx. 20% slower, but should work on all modern 64-bit processors.  More info here:

https://lighthouse-book.sigmaprime.io/installation-binaries.html
```
cd ~
```
```
sudo apt install curl
```
```
curl -LO https://github.com/sigp/lighthouse/releases/download/VERSION/lighthouse-VERSION-ARCHITECTURE-unknown-linux-gnu.tar.gz
```

Stop the Lighthouse client services.
```
sudo systemctl stop lighthousevalidator
```
```
sudo systemctl stop lighthousebeacon
```

Extract the binary from the archive and copy to the /usr/local/bin directory. Modify the URL name as necessary.
```
tar xvf lighthouse-VERSION-ARCHITECTURE-unknown-linux-gnu.tar.gz
```
```
sudo cp lighthouse /usr/local/bin
```

Check version
```
cd /usr/local/bin
```
```
lighthouse -V
```

Restart the Beacon service and check for errors
```
sudo systemctl start lighthousebeacon
```
Check for errors
```
sudo systemctl status lighthousebeacon
```
Monitor
```
sudo journalctl -fu lighthousebeacon
```
Restart the Validator service and check for errors
```
sudo systemctl start lighthousevalidator
```
Check for errors
```
sudo systemctl status lighthousevalidator
```
Monitor  
```
sudo journalctl -fu lighthousevalidator
```

Clean up the extracted files.
```
cd ~
```
```
sudo rm lighthouse
```
```
sudo rm lighthouse-VERSION-ARCHITECTURE-unknown-linux-gnu.tar.gz
```

