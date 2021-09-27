# Infrastructure
This repository contains everything I use to run my home infrastructure.  I put it on github in case others would like to learn.

## Requirements
* Python 3
* SSH installed on each machine
* `ansible` installed on the system

## Setup
The vault password must be defined in `ansible/.vault_pass`.

Install ansible and requirements through `scripts/setup.sh`.

Environment variables needed to operate both `ansible` and `kubectl` are set in `.envrc`.  It is recommended that you install the [direnv](https://github.com/direnv/direnv) application, which automatically sets these when you are in the repository's directory.

## Ansible

### Vault Management
`scripts/encdec.sh` will encrypt or decrypt every `vault.yml` file, as well as all files listed in `encrypted_files.txt`, using your defined `.vault_pass`.  If a line in the text file is a directory, every file underneath that directory will be encrypted.

* `scripts/encdec.sh encrypt`

* `scripts/encdec.sh decrypt`

### Executing

`scripts/deploy.sh` is a simple wrapper around `ansible-playbook` which also adds the vault password file for convenience.  All `ansible-playbook` command line parameters can be added as parameters to this script.

### Playbooks

`everything.yml` is designed to execute the kitchen sink, and calls all other playbooks:

* `linux.yml`: Basic initialization of a clean linux installation, including pushing of public keys, hostname setup, library installations and upgrade to latest packages.  You'll probably need to execute with the `-kK` options and enter your password if executing this for the first time on a clean linux installation.
* `raspberry_pi.yml`: Setup routines that are specific to Raspberry Pi machines, including overclocking if they are in the proper group in the hosts file.
* `avahi.yml`: Avahi service installation and setup for broadcast repeating between subnets.
* `docker.yml`: Installs docker, all docker containers and their respective networks and fileshares.
* `k8s.yml`: Installs kubernetes (using k3s) onto my Raspberry Pi cluster and mounts a drive used for storing backups.

`k8s_wipe.yml`: Destroys the k3s cluster.  It does not touch the mounted backup drive.

### Tags

Generally, tags are set up so that you can call either a specific docker container, or a form of an update which updates various configurations or containers.

* Tagging the docker role will focus on that container (e.g. `node_red`, `nexus`).  It will also create or modify fileshare handles associated with the container.
* `docker_update` will update every non-critical container with the latest from the remote repository.
* `docker_critical_update` will update containers critical to keeping our network running smoothly.

## Kubernetes
The cluster is ran through the [k8s-at-home](https://github.com/k8s-at-home/template-cluster-k3s) template structure which, generally speaking, operates in the following way:

* Rather than deploy on-demand through ansible, Flux watches the git repository and applies changes as they are pushed.  This makes the git repository the de facto source of truth.
* Kubernetes secrets are stored using SOPS through a GPG key instead of the ansible vault

There are a number of `k8s_*` roles still defined.  Those are no longer used and in the process of conversion to the k8s-at-home pattern.

## Segregation of Functions

My infrastructure's functions are in two categories: critical and non-critical.  Critical functions are those that would cripple normal use of our network and internet without manual intervention, such as DHCP, DNS or VPN.  If I can't watch a movie on Plex, or my home automation sensors aren't recording data to Influx, it is not a huge deal.  However, if my wife can't use the internet and is due to give a work presentation there will be hell to pay, and I'm simply too young to die.  With that in mind, I segregate these critical functions to their own physical servers and think of them as "life-support" in both the metaphorical and (potentially) literal sense.  These servers are in their own defined host group in the ansible inventory, so you could use the parameter `--limit '!critical'` to ensure that all playbooks are skipping machines that you really don't want to be touched on a routine basis.

## Notes
* My internal DNS host list and DHCP static reservations are built dynamically using data from my internal Netbox instance, which is my source of truth for all information around my home network (IP address assignments, switch ports, VLANs, etc).
	* Netbox does not support host aliases, so I created tags (e.g. `dnsalias:www`, `dnsalias:plex`) and associated those tags with the IP address stored in Netbox.
	* To build the DHCP static reservations, the following are required for each IP address configured in Netbox:
		* The IP address has a status of `Reserved`.  All IPs without this status are skipped.
		* The IP address has a DNS hostname defined.  If a qualifying IP address entry doesn't have this, the entire task will fail.
		* The IP address has a device and interface associated, and that interface has a MAC address defined.  If the MAC is not defined or the IP address entry has no device and interface associated, the entire task will fail.

## VLANs
My network is separated into the following VLANs:

* **1 - Administrative**: Critical servers, switches and other backbone-level equipment
* **30 - Workstation**: Laptops, phones, other end-user devices
* **40 - IoT**: Home IoT devices.  IoT devices aren't known for their security, so they are segregated to their own network who can't see any other networks other than the upstream internet.
* **50 - Services**: The various services that are usually powered in containerized form through Docker or Kubernetes.
