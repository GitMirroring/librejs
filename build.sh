#!/bin/bash
#
# Build GNU LibreJS entirely from packages provided by the distribution.
# No npm and no network access are required.
#
# On Trisquel 12 / Ubuntu 24.04 the build dependencies are:
#   sudo apt install node-browserify node-acorn node-hash.js zip
# and, to build with the test suite (-t / --test) as well:
#   sudo apt install node-jasmine

set -e

# Debian/Ubuntu install Node.js libraries (acorn, the browserify shims, ...)
# under /usr/share/nodejs. Point browserify's module resolver there so it
# finds them without a local node_modules/ directory.
export NODE_PATH="${NODE_PATH:+$NODE_PATH:}/usr/share/nodejs"

if ! command -v browserify > /dev/null; then
  echo "can not find browserify -- install it with: sudo apt install node-browserify" >&2
  exit 1
fi

WITH_TESTS=""
if [ "$1" == "-t" ] || [ "$1" == "--test" ]; then
  WITH_TESTS=1
fi

# Provide the in-browser Jasmine test runner from the distribution package
# (node-jasmine) instead of downloading it.
if [ -n "$WITH_TESTS" ]; then
  JASMINE_SRC=/usr/share/nodejs/jasmine-core/lib/jasmine-core
  JASMINE_DEST=test/lib/jasmine
  if [ ! -f "$JASMINE_SRC/jasmine.js" ]; then
    echo "can not find Jasmine -- install it with: sudo apt install node-jasmine" >&2
    exit 1
  fi
  mkdir -p "$JASMINE_DEST"
  cp "$JASMINE_SRC"/jasmine.js "$JASMINE_SRC"/jasmine-html.js \
     "$JASMINE_SRC"/boot0.js "$JASMINE_SRC"/boot1.js \
     "$JASMINE_SRC"/jasmine.css "$JASMINE_DEST"/
fi

# Build the main file
browserify main_background.js -o bundle.js

# Create a fresh temp directory
rm -rf ./build_temp
mkdir ./build_temp

# Move source files to temp directory
if [ -n "$WITH_TESTS" ]; then
  cp -r ./test ./build_temp
fi
cp -r ./icons ./build_temp
cp -r ./html ./build_temp
cp -r ./content ./build_temp
cp -r ./common ./build_temp
cp manifest.json ./build_temp
cp bundle.js ./build_temp

# build zip file from temp directory
cd ./build_temp
zip -r librejs.zip ./*
# remove old file
rm -f ../librejs.xpi
# move new zip file
mv librejs.zip ../
# go back to source dir and remove temp directory
cd ../
rm -r ./build_temp
# change the zip file to a xpi file that can be uploaded
mv librejs.zip librejs.xpi
