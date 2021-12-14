# Infrastructure

This repository contains everything I use to run my home infrastructure.  I put it on github in case others would like to learn.  At a high level, it uses the following technologies:

* Ansible for server provisioning and initial kubernetes deployment
* SOPS for secret storage
* K3S for Kubernetes cluster across several servers
* Docker for container needs that are not condusive to the Kubernetes distributed model
* ArgoCD for Kubernetes cluster GitOps deployment
* Helm Secrets for using SOPS secrets inside the Kubernetes cluster

## Requirements

* Python 3
* SSH installed on each machine
* `ansible` installed on the system
* The private GPG key stored on the machine

## Setup

Environment variables needed to operate both `ansible` and `kubectl` are set in `.envrc`.  It is recommended that you install the [direnv](https://github.com/direnv/direnv) application, which automatically sets these when you are in the repository's directory.

## Ansible

### Secrets Management

All secrets are managed by SOPS, through a private GPG key.  It's recommended that you use the SOPS plugin for Visual Studio Code, as it will automatically encrypt and decrypt for ease of use.

### Executing

All non-automatic execution is handled through ansible playbooks.

### Playbooks

Playbooks are found in the ansible/playbooks directory.

#### Docker

`critical_apps_primary.yml` and `critical_apps_secondary.yml` contain containers that are not particularly suited for kubernetes and run mission critical services that are needed for my home, such as DHCP and DNS.  See "Netbox Integration" below for more information on how these are used.

#### Kubernetes

`k8s_install.yml` will install K3S onto all members of the Kubernetes cluster

`k8s_nuke.yml` will delete K3S on all members of the Kubernetes cluster

`reset_longhorn_disks.yml` will wipe longhorn disk information on all members of the Kubernetes cluster.  This is typically ran if you run a cluster-wide execution of `k8s_nuke.yml` for a fully clean slate.

`applications_core.yml` applies the GPG key and all of the core applications onto the Kubernetes cluster, such as ArgoCD, traefik, metallb, and longhorn.

`applications_service.yml` applies all of the service applications onto the Kubernetes cluster.  When re-building the cluster, I will wait for `applications_core.yml` to finish deployments before executing this.

#### Others

`dhcp_update.yml` and `dns_update.yml` are run to sync DHCP and DNS with Netbox.  See the Netbox Integration section below for more.

`provision.yml` is the one-stop-shop which provisions servers end-to-end.  Actions are idempotent so you can run it across all servers whenever you wish.  One action that will often change is a system update of packages.  It is important to note that it will NOT reboot even if a system update requires it.  This is to prevent unwanted consequences in the Kubernetes cluster.  You can run a `rolling-reboot.yml` to reboot the cluster (experimental) or when creating the cluster iteself, `k8s_install.yml` will check if it should be rebooted before installing K3S.

### Tags

Generally, tags are set up so that you can call either a specific docker container, or a form of an update which updates various configurations or containers.

* Tagging the docker role will focus on that container (e.g. `node_red`, `nexus`).  It will also create or modify fileshare handles associated with the container.
* `docker_update` will update every non-critical container with the latest from the remote repository.
* `docker_critical_update` will update containers critical to keeping our network running smoothly.

### Netbox Integration

I utilize the Netbox application as my documented source of truth for all of my connected devices.  In particular, I use it to generate the configurations for DHCP and DNS services.  Each time `dhcp_update.yml` or `dns_update.yml` are called, it will pull a data structure of relevant information from Netbox, then apply it to a template that recreates the configuration for their respective services.

Some additional notes on this:

* Netbox does not support host aliases, so I created tags (e.g. `dnsalias:www`, `dnsalias:plex`) and associated those tags with the IP address stored in Netbox.
* To build the DHCP static reservations, the following are required for each IP address configured in Netbox:
  * The IP address has a status of `Reserved`.  All IPs without this status are skipped.
  * The IP address has a DNS hostname defined.  If a qualifying IP address entry doesn't have this, the entire task will fail.
  * The IP address has a device and interface associated, and that interface has a MAC address defined.  If the MAC is not defined or the IP address entry has no device and interface associated, the entire task will fail.

### Backups

Backups in its current form are experimental.  I originally used Velero but that was more than I needed because all I really need to save is the persistent storage data on a per-application basis, not a holistic disaster recovery system.  I have no need to back up the declarative Kubernetes information because that can be automatically regenerated.  Additionally, I have some services that are best to be backed up differently.  For instance, Netbox's data is all stored in Postgres, and I'd be better off saving a Postgres dump than to back up the data volume.  Services that use SQLite can also be very finnicky if you back up their data through the volume.  And when it comes to backups, I need 100% confidence, so I'd rather run something that is not as smooth but will give me exactly what I want.

I have a simple container `ghcr.io/fred-drake/k8s-backup` which runs on each namespace that needs it.  It ties into the persistent volume claim and uses restic to back up to a Minio S3 instance.

## VLANs

My network is separated into the following VLANs:

* **1 - Administrative**: Critical servers, switches and other backbone-level equipment
* **30 - Workstation**: Laptops, phones, other end-user devices
* **40 - IoT**: Home IoT devices.  IoT devices aren't known for their security, so they are segregated to their own network who can't see any other networks other than the upstream internet.
* **50 - Services**: The various services that are usually powered in containerized form through Docker or Kubernetes.
