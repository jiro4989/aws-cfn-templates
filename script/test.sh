#!/bin/bash

set -eux

for file in $(find template/ -name '*.yml'); do
  aws cloudformation validate-template --template-body "file://${file}"
done
