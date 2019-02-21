#!/usr/bin/env bash

set -euo pipefail

TMP_DIR=$(mktemp -d)
BOSH_DIR="bosh"
CONCOURSE_DIR="concourse"
CONCOURSE_USER="admin"
CONCOURSE_PASSWORD=$(uuidgen)
CREDHUB_ADMIN="admin"
CREDHUB_PASSWORD=$(uuidgen)
UAA_VERSION="67.0"
UAA_SHA1="b07e17aff8caaf36d7c8263f5b0cd2cf64f1ad1f"

echo -ne "Env name: \n"
read -r ENV_NAME
echo -ne "Domain name: \n"
read -r DOMAIN_NAME

cat > ~/.concourserc <<EOF
export CONCOURSE_USER=$CONCOURSE_USER
export CONCOURSE_PASSWORD=$CONCOURSE_PASSWORD
EOF

cat > ~/.credhub_concourse <<EOF
export CREDHUB_ADMIN=$CREDHUB_ADMIN
export CREDHUB_PASSWORD=$CREDHUB_PASSWORD
EOF

function tearDown {
    rm -rf "$TMP_DIR"
}

trap tearDown EXIT
source ~/.boshrc

if [ ! -d "$CONCOURSE_DIR" ]
then
    git clone https://github.com/concourse/concourse-bosh-deployment.git "$CONCOURSE_DIR"
fi

cat > "$CONCOURSE_DIR"/cluster/cloud_configs/gcp.yml <<EOF
azs:
- name: z1
  cloud_properties: {zone: europe-west1-c}

vm_types:
- name: default
  cloud_properties:
    machine_type: n1-standard-4
    root_disk_size_gb: 20
    root_disk_type: pd-ssd
- name: worker
  cloud_properties:
    machine_type: n1-standard-4
    root_disk_size_gb: 100
    root_disk_type: pd-ssd

disk_types:
- name: default
  disk_size: 3000

networks:
- name: concourse
  type: manual
  subnets:
  - range:   10.0.30.0/24
    gateway: 10.0.30.1
    dns:     [8.8.8.8, 8.8.4.4]
    azs:     [z1]
    static:  10.0.30.10
    cloud_properties:
      network_name: ${ENV_NAME}-mgmt-network
      subnetwork_name: ${ENV_NAME}-concourse-subnet
      ephemeral_external_ip: false
      tags: [cm-allow-internal, concourse, ${ENV_NAME}-concourselb, cm-httplb, ${ENV_NAME}-cm-httplb, cm-${ENV_NAME}-allow-http, bosh-internal, cm-${ENV_NAME}-allow-http]

disk_types:
- name: db
  disk_size: 10240

compilation:
  workers: 3
  reuse_compilation_vms: true
  az: z1
  vm_type: worker
  network: concourse

vm_extensions:
- name: backend-pool
  cloud_properties:
    ephemeral_external_ip: false
    target_pool: cm-${ENV_NAME}-http-lb 
EOF

cat > "$CONCOURSE_DIR"/cluster/uaa_version.yml <<EOF
---
uaa_version: "${UAA_VERSION}"
uaa_sha1: "${UAA_SHA1}"
EOF

curl -L 'https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-xenial-go_agent?v=170.13' \
    -o "$TMP_DIR/xenial-go-agent.tgz"

bosh -e bosh-mgmt upload-stemcell "$TMP_DIR/xenial-go-agent.tgz"

bosh -e bosh-mgmt \
    -n update-cloud-config "$CONCOURSE_DIR"/cluster/cloud_configs/gcp.yml

credhub_ca_cert=$(bosh int "$BOSH_DIR"/secrets.yml --path /credhub_ca/ca)
cat > credhub_ca.cert <<EOF
$credhub_ca_cert
EOF

cat > "$CONCOURSE_DIR"/cluster/credhub_ca.yml <<EOF
---
credhub_ca_cert: |
$(cat credhub_ca.cert | sed "s/^/  /g")
EOF

bosh int "$CONCOURSE_DIR"/cluster/concourse.yml \
    -l "$CONCOURSE_DIR"/versions.yml \
    -l "$CONCOURSE_DIR"/cluster/uaa_version.yml \
    -l "$CONCOURSE_DIR"/cluster/credhub_ca.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/static-web.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/basic-auth.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/uaa.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/credhub.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/web-network-extension.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/tls-vars.yml \
	--var local_user.username="$CONCOURSE_USER" \
	--var local_user.password="$CONCOURSE_PASSWORD" \
	--var web_ip=10.0.30.10 \
	--var external_url=http://ci.${ENV_NAME}.${DOMAIN_NAME}:8080 \
	--var network_name=concourse \
	--var web_vm_type=default \
	--var db_vm_type=default \
	--var db_persistent_disk_type=db \
	--var worker_vm_type=worker \
	--var deployment_name=concourse \
	--var credhub_url=https://10.0.30.10:8443 \
	--var credhub_client_id="$CREDHUB_ADMIN" \
	--var credhub_client_secret="$CREDHUB_PASSWORD" \
	--var external_host=concourse."${ENV_NAME}.${DOMAIN_NAME}" \
	--var web_network_vm_extension=backend-pool \
	--var web_network_name=concourse \
    --vars-store "$CONCOURSE_DIR"/cluster/secrets.yml

bosh -e bosh-mgmt -n deploy -d concourse "$CONCOURSE_DIR"/cluster/concourse.yml \
	-l "$CONCOURSE_DIR"/versions.yml \
	-l "$CONCOURSE_DIR"/cluster/secrets.yml \
    -l "$CONCOURSE_DIR"/cluster/uaa_version.yml \
    -l "$CONCOURSE_DIR"/cluster/credhub_ca.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/static-web.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/basic-auth.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/uaa.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/credhub.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/web-network-extension.yml \
	-o "$CONCOURSE_DIR"/cluster/operations/tls-vars.yml \
	--var local_user.username="$CONCOURSE_USER" \
	--var local_user.password="$CONCOURSE_PASSWORD" \
	--var web_ip=10.0.30.10 \
	--var external_url=http://ci.${ENV_NAME}.${DOMAIN_NAME}:8080 \
	--var network_name=concourse \
	--var web_vm_type=default \
	--var db_vm_type=default \
	--var db_persistent_disk_type=db \
	--var worker_vm_type=worker \
	--var deployment_name=concourse \
	--var credhub_url=https://10.0.30.10:8443 \
	--var credhub_client_id="$CREDHUB_ADMIN" \
	--var credhub_client_secret="$CREDHUB_PASSWORD" \
	--var external_host=concourse."${ENV_NAME}.${DOMAIN_NAME}" \
	--var web_network_vm_extension=backend-pool \
	--var web_network_name=concourse
