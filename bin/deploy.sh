#!/usr/bin/env bash

set -e

# Loads DEST_PATH
# shellcheck disable=SC1091
source .env

ROOT_PATH=$(cd "$(dirname "$0")"; pwd -P)/../
SRC_PATH="${ROOT_PATH:?}/_site"
SRC_PATH_TMP="${ROOT_PATH:?}/_deploy"

if [[ -z "$DEST_PATH" ]]; then
  echo "\$DEST_PATH cannot be empty" >&2
  exit 1
fi

export JEKYLL_ENV=production

# Setup
npm run setup

# Build
npm run build

# Lint
npm run lint:scss
npm run lint:js
npm run lint:html
npm run lint:md

# Freeze Build
mkdir -p "${SRC_PATH_TMP:?}/"
mv "${SRC_PATH:?}/"* "${SRC_PATH_TMP:?}/"
cd "${SRC_PATH_TMP:?}/"

# Optimize Images
find . -name '*.jpg' -type f -exec sh -c 'jpegtran -outfile "$1" -perfect -copy none "$1"' _ {} \;
find . -name '*.png' -type f -exec sh -c 'oxipng -o 3 -i 1 --strip all "$1"' _ {} \;

# Remove Extraneous Files
find . -name '*.gz' -type f -delete
rm assets/.sprockets-manifest-*.json

# Sync Build with Production
rsync -av --delete . "${DEST_PATH:?}/"

# Cleanup
npm run clean
