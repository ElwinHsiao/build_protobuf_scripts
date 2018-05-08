#!/bin/sh
MODE=$1
NDK_BUILD=~/Library/Android/android-ndk-r10e/ndk-build


realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}


SCRIPT_DIR=$(realpath $(dirname $0))
TOP_BUILD_DIR=$SCRIPT_DIR/build
BUILD_DIR=$TOP_BUILD_DIR/android
PWD=$(pwd)


cd $SCRIPT_DIR/jni
$NDK_BUILD $MODE
mkdir -p $BUILD_DIR 2>/dev/null
OBJ_DIR=$SCRIPT_DIR/obj/local
rsync -am --include='*.so'  --include='*.a' --include='*/' --exclude='*' $OBJ_DIR $TOP_BUILD_DIR
rm -rf $BUILD_DIR 2>/dev/null
mv $TOP_BUILD_DIR/local $BUILD_DIR
find $BUILD_DIR -name "objs" -type d |xargs rm -rf
echo "libs: $BUILD_DIR"
tree $BUILD_DIR

HEADER_DIR=$TOP_BUILD_DIR/include
rm -rf $HEADER_DIR 2>/dev/null
mkdir -p $HEADER_DIR 2>/dev/null

FILES=$(cat $SCRIPT_DIR/lite_headers.txt |sed 's,.*/,,;s/^/--include=/')
# echo $FILES
rsync -am $FILES --include='*/' --exclude='*' $SCRIPT_DIR/protobuf/src/google $HEADER_DIR
# echo 'rsync -a --include="'$FILES'" --include='*/' --exclude='*' '$SCRIPT_DIR'/protobuf/src/google $HEADER_DIR'
echo "headers: $HEADER_DIR"
tree $HEADER_DIR

# HEADER_SOURCE_DIR=$HEADER_DIR/include/google/protobuf
# HEADER_DEST_DIR=$HEADER_DIR/include/google/protobuf
# while read line ; do
# 	echo $line
# 	cp $HEADER_SOURCE_DIR/$line $HEADER_DEST_DIR
# done < lite_headers.txt


