#!/usr/bin/env bash

set -euo pipefail

cp -a terraform-pivotalcf/* tf-src/
cp -a terraform-tfvars/*.tfvars tf-src/terraforming-pas/terraform.tfvars
if [ -f "tf-src/terraforming-pas/terraform.tfvars" ]
then
    echo "terraform.tfvars was successfully copied to tf-src/terraforming-pas/terraform.tfvars"
else
    echo "Something went wrong when copying terraform.tfvars to tf-src :("
fi
# cp -a terraform-pivotalcf/terraforming-pas/vm.tags vm-tags/vm.tags