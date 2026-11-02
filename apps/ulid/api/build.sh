#!/usr/bin/env bash
# Builds the Lambda package folder: handler + its dependencies.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build
mkdir -p build
pip install --quiet --target build -r requirements.txt
cp handler.py build/
echo "Lambda package ready in apps/ulid/api/build"
