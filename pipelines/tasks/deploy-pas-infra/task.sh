#!/usr/bin/env bash

set -euo pipefail

cp -a terraform-tfvars/*.tfvars terraform-pivotalcf/terraforming-pas/terraform.tfvars
# cp -a terraform-pivotalcf/terraforming-pas/vm.tags vm-tags/vm.tags