#!/bin/bash

set -e
gemfile="$1"

cd `dirname "$gemfile"`
if [ -e "$gemfile".dir ]; then
  echo "error:$gemfile.dir already exists!" 1>&2
  exit 1
fi
mkdir "$gemfile".dir
cd "$gemfile".dir
tar xf ../`basename "$gemfile"`
gunzip checksums.yaml.gz
gunzip metadata.gz
mkdir data
cd data
  tar xzf ../data.tar.gz
cd ..
rm -f data.tar.gz
find . -type f -print | cut -d/ -f2- | egrep -v '^(MANIFEST|checksums\.yaml)$' | xargs -L20 sha256sum >MANIFEST
