#!/bin/bash

set -eux

find src/ -name '*.yml' \
  -exec aws cloudformation validate-template --template-body "file://{}" ";"
