#!/bin/sh

NDK=~/Library/Android/android-ndk-r10e
OPER_SYS=darwin-x86_64
ANDROID_PLATFORM=21
TOOL_VERSION=4.9
ARCHS=(arm arm64 x86 x86_64 mips mips64)

function build_one {
    mkdir -p build/$ARCH
    cd protobuf

    CFLAGS="-march=$ARCH"

    export CC="$CC --sysroot $SYSROOT"
    export CXX="CXX --sysroot $SYSROOT"

    ./configure --prefix=../build/$ARCH \
        --host=$ARCH_HOST \
        --with-sysroot=$SYSROOT \
        --enable-static \
        --disable-shared \
        --enable-cross-compile \
        --with-protoc=protoc LIBS="-lc -llog" \
        CFLAGS=$CFLAGS \
        CXXFLAGS="$CFLAGS -I$CXXSTL/include -lgnustl_static"

    make clean
    make -j4
    make install
    cd ..
}

for (( i=0; i<1; i++ )); do
#for (( i=0; i<${#ARCHS[@]}; i++ )); do
    ARCH=${ARCHS[$i]}

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

    echo "Build $ARCH"
    build_one
done

