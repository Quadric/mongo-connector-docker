#!/bin/bash

set -e #o pipefail

tag=$(<tag)

docker build -t "$tag" .
