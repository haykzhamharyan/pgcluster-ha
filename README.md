# PostgreSQL HA Cluster

### Deploy a PostgreSQL High-Availability Cluster on DigitalOcean Cloud platform (based on "Patroni" and DCS "consul")  automating with Ansible.

The Terraform manifests (terraform directory) are designed for deploying droplets on DigitalOcean and the ansible playbook and roles are designed to deploy a PostgreSQL HA cluster (with DCS consul and haproxy) on virtual machines and in the cloud. 

## Architecture overview

Deployment scheme:
(images/scheme.png)

This scheme is suitable for master-only access and for load balancing (using DNS) for reading across replicas. Consul [Service Discovery](https://developer.hashicorp.com/consul/docs/concepts/service-discovery) with [DNS resolving ](https://developer.hashicorp.com/consul/docs/discovery/dns) is used as a client access point to the database.

Client access points:

- `master.postgres.service.consul`
- `replica.postgres.service.consul`


---
## Compatibility OS
- **Ubuntu**: 20.04

###### PostgreSQL versions: 
Tested PostgreSQL 16 

###### Terraform version 
Tested Terraform v1.5.7

###### Ansible version 
Minimum supported Ansible version: 2.11.0

## Requirements
This playbook requires root privileges or sudo.
DIGITALOCEAN_TOKEN 
Ansible
Terraform

## Port requirements
List of required TCP ports that must be open for the database cluster:

- `5432` (postgresql)
- `6432` (pgbouncer)
- `8008` (patroni rest api)
- `8300` (Consul Server RPC)
- `8301` (Consul Serf LAN)
- `8302` (Consul Serf WAN)
- `8500` (Consul HTTP API)
- `8600` (Consul DNS server)


---
## Before you begin set appropriate variables and values
Droplet size, region and names in `terraform/main.tf` file.

## Deployment Steps: (quick start)
0. Install dependancies. 
```
sudo apt update && sudo apt install -y ansible sshpass git
```

1. Download or clone this repository
```
git clone https://github.com/haykzhamharyan/pgcluster-ha
```

2. Export DIGITALOCEAN_TOKEN to your environment
```
export DIGITALOCEAN_TOKEN="YOUR API TOKEN"
```

3. Got to terraform directory and initialise it.
```
cd terraform && terraform --init
```

4. Test with terraform plan to make sure all resources has been configured properly.  
```
terraform plan
```

5. Apply to create the resources in the cloud.
```
terraform apply -auto-approve
```

> :heavy_exclamation_mark: Do Not edit ansible inventory. This step will generate ansible inventory file based on terraform output.


6. Go to the parent directory and run the playbook

```
cd .. && ansible-playbook playbook.yml -i inventory.ini --ask-vault-pass
```
> :heavy_exclamation_mark: Default vault pass is 'root12'. You should create your vault.yml with root_password: and postgres_password: .

## Validation 
Consul DNS
dig @127.0.0.1 -p 8600 master.postgres.service.consul +short
dig @127.0.0.1 -p 8600 replica.postgres.service.consul +short