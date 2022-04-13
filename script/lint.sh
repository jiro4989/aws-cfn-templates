#!/bin/bash

set -eux

find src/ -name '*.yml' -exec cfn-lint -r ap-northeast-1 -t '{}' \;
