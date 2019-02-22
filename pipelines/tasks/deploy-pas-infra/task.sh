#!/usr/bin/env bash

set -euo pipefail

cp -a terraform-pivotalcf/* tf-src/
cp -a terraform-tfvars/*.tfvars tf-src/terraforming-pas/terraform.tfvars
cat tf-src/terraforming-pas/terraform.tfvars
# cp -a terraform-pivotalcf/terraforming-pas/vm.tags vm-tags/vm.tags