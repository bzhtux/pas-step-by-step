#!/usr/bin/env bash

set -xeuo pipefail

cat <<EOF > secrets-output/env.yml
---
target: $OPSMAN_TARGET
connect-timeout: 30
request-timeout: 1800
skip-ssl-validation: true
username: $OPSMAN_ADMIN
password: $OPSMAN_PASSWORD
decryption-passphrase: $OPSMAN_PASSPHRASE
EOF

cat secrets-output/env.yml

cat <<EOF > secrets-output/auth.yml
---
username: $OPSMAN_ADMIN
password: $OPSMAN_PASSWORD
decryption-passphrase: $OPSMAN_PASSPHRASE
EOF

cat secrets-output/auth.yml

OPSMAN_PUBLIC_IP=$(dig +short pcf.dev.bzhtux-lab.net)

cat <<EOF > secrets-output/opsman.yml
---
opsman-configuration:
  gcp:
    gcp_service_account: |
      {
        "type": "service_account",
        "project_id": "$GCP_PROJECT_ID",
        "private_key_id": "$GCP_PRIVATE_KEY_ID",
        "private_key": "$GCP_PRIVATE_KEY",
        "client_email": "concourse-bosh@cso-pcfs-emea-bzhtux.iam.gserviceaccount.com",
        "client_id": "108059996474957115330",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/concourse-bosh%40cso-pcfs-emea-bzhtux.iam.gserviceaccount.com"
      }
    project: $GCP_PROJECT_ID
    region: europe-westc
    zone: europe-west1-c
    vm_name: opsmanager               # default: OpsManager-vm
    # For SharedVPC: projects/[HOST_PROJECT_ID]/regions/[REGION]/subnetworks/[SUBNET]
    vpc_subnet: dev-infrastructure-subnet
    tags: dev-ops-manager-external
    # This CPU, Memory and disk size demonstrated here
    # match the defaults, and needn't be included if these are the desired values
    custom_cpu: 2
    custom_memory: 8
    boot_disk_size: 100
    # At least one IP address (public or private) needs to be assigned to the VM.
    public_ip: $OPSMAN_PUBLIC_IP
    private_ip: 10.0.0.2
EOF

cat secrets-output/opsman.yml