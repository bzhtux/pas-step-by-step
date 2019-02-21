#!/usr/bin/env bash

set -euo pipefail

pipelines_dir="$(dirname "$0")"

if [ "$#" -ne 1 ]; then
    fly_target="ci-dev"
    echo "Using $fly_target as fly target"
else
    fly_target="$1"
fi

fly -t "$fly_target" sp -p install-pas \
    -c "${pipelines_dir}/pipeline.yml" \
    -l "${pipelines_dir}/config/params.yml"

fly -t "$fly_target" up -p install-pas
