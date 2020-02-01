#!/usr/bin/env sh

curl -s https://raw.githubusercontent.com/jeroenmanders/data/master/aws/ec2_regions.json | jq -r '.Regions[] | .RegionName';
