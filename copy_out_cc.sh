#!/bin/sh

CPP_DIR=build/cpp
mkdir -p $CPP_DIR

FILES=$(cat lite_files.txt |sed 's,.*/,,;s/^/--include=/')
# echo $FILES
rsync -am $FILES --include='*/' --exclude='*' protobuf/src/google $CPP_DIR

tree $CPP_DIR