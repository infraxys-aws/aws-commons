#!/usr/bin/env bash

set -euo pipefail

for image_dir in $(ls -d */ ); do
    cd "$image_dir"
    image_name="quay.io/jeroenmanders/aws-core-attribute-$(basename "$image_dir")";
    VERSION="$(cat VERSION)";
    docker build -t $image_name:$VERSION .;
done;
