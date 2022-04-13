#!/bin/bash

set -eux

for file in $(find src/ -name '*.yml'); do
  cfn-lint "$file"
done
