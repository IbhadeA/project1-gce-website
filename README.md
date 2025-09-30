![Lint](https://github.com/ibhadeA/project1-gce-website/actions/workflows/lint.yml/badge.svg)

# Project 1 — Static Website on Google Compute Engine (London)

**Project ID:** `web-demo-473709`  
**Region/Zone:** `europe-west2` / `europe-west2-a`

---

## Overview
This project deploys a **static website** on Google Cloud using:
- A custom **VPC** and **subnet**
- **Firewall rules** applied by **network tag (`web`)**
- A **Compute Engine VM (e2-micro)** running Debian 12
- A **startup script** that installs Nginx and serves a simple HTML page

---

## Architecture

Internet
│
Firewall Rule (allow tcp:80 → tag:web)
│
VPC: web-vpc ── Subnet: web-subnet (10.10.0.0/24)
│
[ VM: web-vm-1 (e2-micro, Debian 12, Nginx via startup script) ]


---

## Deployment Steps (CLI)

> Assumes: project `web-demo-473709`, region `europe-west2`, zone `europe-west2-a`.

### 1) Create VPC and subnet

gcloud compute networks create web-vpc --subnet-mode=custom
gcloud compute networks subnets create web-subnet \
  --network=web-vpc --region=europe-west2 --range=10.10.0.0/24
  
### 2) Firewall rules

## Allow HTTP (80) to VMs tagged "web"
gcloud compute firewall-rules create web-allow-http \
  --network=web-vpc --allow=tcp:80 --target-tags=web

## Allow SSH via IAP (safer than 0.0.0.0/0)
gcloud compute firewall-rules create web-allow-ssh-iap \
  --network=web-vpc --allow=tcp:22 \
  --source-ranges=35.235.240.0/20 --target-tags=web

### 3) Startup script
See [startup.sh](https://chatgpt.com/g/g-p-685283b26f9881a49f72822ac5aff215/c/startup.sh).
It installs Nginx and writes an index.html showing the VM hostname and zone.

### 4) Create the VM

gcloud compute instances create web-vm-1 \
  --machine-type=e2-micro \
  --image-family=debian-12 --image-project=debian-cloud \
  --network=web-vpc --subnet=web-subnet \
  --tags=web \
  --metadata-from-file startup-script=startup.sh
  
### 5) Test the site
gcloud compute instances list --filter="name=web-vm-1" \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
Open the external IP in your browser → you should see “It works! 🚀”.

## Troubleshooting
Check startup logs

gcloud compute ssh web-vm-1 --tunnel-through-iap \
  --command="sudo journalctl -u google-startup-scripts --no-pager"
Verify tags and rules


gcloud compute instances describe web-vm-1 --format="get(tags.items)"
gcloud compute firewall-rules list --filter="name~'web-allow'"

---

## Cleanup

gcloud compute instances delete web-vm-1 --zone=europe-west2-a --quiet
gcloud compute firewall-rules delete web-allow-http --quiet
gcloud compute firewall-rules delete web-allow-ssh-iap --quiet
gcloud compute networks subnets delete web-subnet --region=europe-west2 --quiet
gcloud compute networks delete web-vpc --quiet

---

## Key Learnings
- Prefer network tags over IPs for firewall rules (portable & dynamic).

- Startup scripts make VM setup reproducible and hands-free.

- Use IAP for SSH instead of opening SSH to the internet.
