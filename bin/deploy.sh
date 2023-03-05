#!/usr/bin/env bash

set -e

# Loads CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_PROJECT_NAME
# shellcheck disable=SC1091
source .env

ROOT_PATH=$(cd "$(dirname "$0")"; pwd -P)/../
SRC_PATH="${ROOT_PATH:?}/_site"
SRC_PATH_TMP="${ROOT_PATH:?}/_deploy"

if [[ -z "$CLOUDFLARE_ACCOUNT_ID" ]]; then
  echo "\$CLOUDFLARE_ACCOUNT_ID cannot be empty" >&2
  exit 1
fi

if [[ -z "$CLOUDFLARE_PROJECT_NAME" ]]; then
  echo "\$CLOUDFLARE_PROJECT_NAME cannot be empty" >&2
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

# Minify HTML
../node_modules/.bin/html-minifier-terser \
  --collapse-boolean-attributes \
  --collapse-whitespace \
  --decode-entities \
  --minify-css \
  --minify-js \
  --remove-attribute-quotes \
  --remove-comments \
  --remove-empty-attributes \
  --remove-optional-tags \
  --remove-redundant-attributes \
  --remove-script-type-attributes \
  --remove-style-link-type-attributes \
  --sort-attributes \
  --sort-class-name \
  --use-short-doctype \
  --file-ext html \
  --input-dir . \
  --output-dir .

# Optimize Images
find . -name '*.jpg' -type f -exec sh -c 'jpegtran -outfile "$1" -perfect -copy none "$1"' _ {} \;
find . -name '*.png' -type f -exec sh -c 'oxipng -o 3 -i 1 --strip all "$1"' _ {} \;

# Remove Extraneous Files
find . -name '*.gz' -type f -delete
rm assets/.sprockets-manifest-*.json

# Copy Cloudflare Pages config files
cp ../_headers ../_redirects .

# Push to Cloudflare Pages
CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" npx wrangler pages publish --project-name "$CLOUDFLARE_PROJECT_NAME" .

# Cleanup
npm run clean
