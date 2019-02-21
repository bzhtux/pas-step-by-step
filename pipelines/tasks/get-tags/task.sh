#!/usr/bin/env bash

set -euo pipefail

VM_TAGS=$(grep vm-tags/vm.tags)

echo "VM_TAGS: ${VM_TAGS}"