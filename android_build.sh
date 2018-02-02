#!/bin/bash

NDK=~/Library/Android/android-ndk-r10e
OPER_SYS=darwin-x86_64
ANDROID_PLATFORM=21
TOOL_VERSION=4.9
export CXXSTL=$NDK/sources/cxx-stl/gnu-libstdc++/$TOOL_VERSION

ARCHS=(arm x86)
#ARCHS=(arm arm64 x86 x86_64 mips mips64)

PWD_DIR=$(pwd)
BUILD_DIR=$PWD_DIR/build


function setup_one {
    TOOL=$ARCH    
    if [ $ARCH = "arm64" ]; then
        TOOL="aarch64"
    elif [ $ARCH = "mips" -o $ARCH = "mips64" ]; then
        TOOL="${TOOL}el"
    fi

    TOOL_BIN=$TOOL
    if [ $ARCH = "x86" ]; then
        TOOL_BIN="i686"
    fi

    TOOL_SFX=linux-android
    if [ $ARCH = "arm" ]; then
        TOOL_SFX="linux-androideabi"
    fi

    TOOL_DIR=$TOOL
    if [ $ARCH != "x86" -a $ARCH != "x86_64" ]; then
        TOOL_DIR=$TOOL_DIR-$TOOL_SFX
    fi

    
    SYSROOT=$NDK/platforms/android-$ANDROID_PLATFORM/arch-$ARCH
    TOOLCHAIN=$NDK/toolchains/$TOOL_DIR-$TOOL_VERSION/prebuilt/$OPER_SYS
    
    ARCH_HOST=$TOOL_BIN-$TOOL_SFX
    CCPRE=$TOOLCHAIN/bin/$ARCH_HOST
    CC=$CCPRE-gcc
    CXX=$CCPRE-g++
    AR=$CCPRE-ar

    if [ ! -d $SYSROOT ]; then
        echo "error $ARCH: SYSROOT=$SYSROOT"
        exit 1
    fi
    if [ ! -d $TOOLCHAIN ]; then
        echo "error $ARCH: TOOLCHAIN=$TOOLCHAIN"
        exit 1
    fi
    if [ ! -f $CC ]; then
        echo "error $ARCH: CC=$CC"
        exit 1;
    fi
}


function build_one {
    BUILD_SUB_DIR=$BUILD_DIR/$ARCH
    mkdir -p $BUILD_SUB_DIR 
    cd $PWD_DIR/protobuf

    CFLAGS="--sysroot $SYSROOT -DPOSIX -DANDROID -DSIGSLOT_USE_POSIX_THREADS"
    if [ "$1" = "armv7" ]; then
        CFLAGS="$CFLAGS -march=armv7-a -I$CXXSTL/libs/armeabi/include -target armv7-none-linux-androideabi"
        BUILD_SUB_DIR=$BUILD_DIR/armeabi-v7a
    elif [ $ARCH = "arm" ]; then
        CFLAGS="$CFLAGS -I$CXXSTL/libs/armeabi/include"
        BUILD_SUB_DIR=$BUILD_DIR/armeabi
    elif [[ $ARCH = "arm64" ]]; then
        CFLAGS="$CFLAGS -march=armv8-a -I$CXXSTL/libs/arm64-v8a/include"
        BUILD_SUB_DIR=$BUILD_DIR/arm64-v8a
    else
        CFLAGS="$CFLAGS -I$CXXSTL/libs/$ARCH/include"
    fi

    ./configure --prefix=$BUILD_SUB_DIR \
        --host=$ARCH_HOST \
        --with-sysroot=$SYSROOT \
        --enable-static \
        --enable-shared \
        --enable-cross-compile \
        --with-protoc=protoc LIBS="-lc -llog" \
        CC=$CC CXX=$CXX \
        CFLAGS=$CFLAGS \
        CXXFLAGS="$CFLAGS -I$CXXSTL/include -L$CXXSTL/libs -lgnustl_static"

    #local RET=$?    # the $? will raise error

    make clean
    make -j $(sysctl -n hw.logicalcpu_max)
    if [ $? -ne 0 ]; then
        echo "make error"
        exit 1
    fi
    #make install
    cp src/.libs/libprotobuf.a $BUILD_SUB_DIR/
    cp src/.libs/libprotobuf-lite.a $BUILD_SUB_DIR/
    cp src/.libs/libprotobuf.so $BUILD_SUB_DIR/ 2>/dev/null
    cp src/.libs/libprotobuf-lite.so $BUILD_SUB_DIR/ 2>/dev/null
    cd $PWD_DIR
}

#for (( i=0; i<1; i++ )); do
for (( i=0; i<${#ARCHS[@]}; i++ )); do
    ARCH=${ARCHS[$i]}

    echo "setup $ARCH"
    setup_one

    echo "Build $ARCH"
    build_one
done


ARCH=arm
echo "setup armv7"
setup_one

echo "build armv7"
build_one armv7


