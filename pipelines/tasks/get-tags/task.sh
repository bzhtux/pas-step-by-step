#!/usr/bin/env bash

set -euo pipefail

cp -a tf-src/terraforming-pas/vm.tags vm-tags/vm.tags

VM_TAGS=$(grep vm-tags/vm.tags)

echo "VM_TAGS: ${VM_TAGS}"