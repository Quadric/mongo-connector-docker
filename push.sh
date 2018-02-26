#!/bin/bash

set -e #o pipefail

tag=$(<tag)

docker push "$tag"
