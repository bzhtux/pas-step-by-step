#!/usr/bin/env bash

set -euo pipefail

TMP_DIR=$(mktemp -d)
BOSH_DIR="bosh"

function tearDown {
    rm -rf "$TMP_DIR"
}

trap tearDown EXIT

echo -ne "GCP project name: \n"
read -r GCP_PROJECT

echo -ne "GCP zone: \n"
read -r GCP_ZONE

echo -ne "ENV_NAME: \n"
read -r ENV_NAME


# update os and install prerequisites
sudo apt update --yes
sudo apt install --yes build-essential \
                       jq \
                       ruby-dev \
                       unzip

# install cloud foundry uaa client
sudo gem install --no-ri --no-rdoc cf-uaac

# Install pivnet cli
PN_VERSION=0.0.55
if [ ! -f "/usr/local/bin/pivnet" ]
then
	wget -O "$TMP_DIR"/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v${PN_VERSION}/pivnet-linux-amd64-${PN_VERSION} && \
  chmod +x "$TMP_DIR"/pivnet && \
  sudo mv "$TMP_DIR"/pivnet /usr/local/bin/
fi

# Install BOSH cli
BOSH_VERSION=5.4.0
if [ ! -f "/usr/local/bin/bosh" ]
then
	wget -O "$TMP_DIR"/bosh \
		https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VERSION}-linux-amd64 \
  && chmod +x "$TMP_DIR"/bosh \
  && sudo mv "$TMP_DIR"/bosh /usr/local/bin/
fi

# Install fly cli
FLY_VERION=4.2.2
if [ ! -f "/usr/local/bin/fly" ]
then
	wget -O "$TMP_DIR"/fly \
		https://github.com/concourse/concourse/releases/download/v${FLY_VERION}/fly_linux_amd64 \
  && chmod +x "$TMP_DIR"/fly \
  && sudo mv "$TMP_DIR"/fly /usr/local/bin/
fi

# Test binaries are successfully installed
type unzip; type jq; type uaac; type pivnet; type bosh; type fly

# clone bosh deployment repository
if [ ! -d "$BOSH_DIR" ]
then
    git clone https://github.com/cloudfoundry/bosh-deployment.git "$BOSH_DIR"
fi

# create bosh env
bosh int "$BOSH_DIR"/bosh.yml \
  -v internal_ip=10.0.20.10 \
	-o "$BOSH_DIR/gcp/cpi.yml" \
	-o "$BOSH_DIR/uaa.yml" \
	-o "$BOSH_DIR/credhub.yml" \
	--vars-store "$BOSH_DIR"/secrets.yml

bosh create-env "$BOSH_DIR"/bosh.yml \
		--state=state.json \
		-l "$BOSH_DIR"/secrets.yml \
		-o "$BOSH_DIR"/gcp/cpi.yml \
		-o "$BOSH_DIR"/uaa.yml \
		-o "$BOSH_DIR"/credhub.yml \
		-v director_name=bosh-mgmt \
		-v internal_cidr=10.0.20.0/24 \
		-v internal_gw=10.0.20.1 \
		-v internal_ip=10.0.20.10 \
		--var-file gcp_credentials_json=gcp_auth.json \
		-v project_id="$GCP_PROJECT" \
		-v tags=["bosh-internal"] \
		-v zone="$GCP_ZONE" \
		-v network="$ENV_NAME"-mgmt-network \
		-v subnetwork="$ENV_NAME"-bosh-subnet

# create target with alias
bosh alias-env bosh-mgmt -e 10.0.20.10 \
	--ca-cert <(bosh int bosh/secrets.yml --path /director_ssl/ca)

cat > ~/.boshrc <<EOF
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh int bosh/secrets.yml --path /admin_password)
EOF
