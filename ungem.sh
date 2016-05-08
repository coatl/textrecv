#!/bin/bash

set -e
gemfile="$1"

cd `dirname "$gemfile"`
mkdir "$gemfile".dir
cd "$gemfile".dir
tar xf ../`basename "$gemfile"`
gunzip checksums.yaml.gz
gunzip metadata.gz
tar tzf data.tar.gz >contents
mkdir data
cd data
tar xzf ../data.tar.gz
rm -f ../data.tar.gz
