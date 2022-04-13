#!/bin/bash

set -eux

for file in $(find src/ -name '*.yml'); do
  aws cloudformation validate-template --template-body "file://${file}"
done
