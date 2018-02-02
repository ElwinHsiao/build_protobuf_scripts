#!/bin/sh

XCODE_DIR=`xcode-select --print-path`
if [ ! -d "$XCODE_DIR" ]; then
	echo "You have to install Xcode and the command line tools first"
	exit 1
fi

PWD_DIR=`pwd`
PB_DIR=$PWD_DIR/protobuf
cd $PB_DIR

if [ ! -x "$PB_DIR/configure" ]; then
	echo "protobuf needs external tools to be compiled"
	echo "Make sure you have autoconf, automake and libtool installed"

	./auto_gen.sh

	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the auto_gen script"
		cd "$PWD_DIR"
		exit $EXITCODE
	fi
fi

# CC=$XCODE_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
# CXX=$XCODE_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
# IPHONEOS_DEPLOYMENT_TARGET="8"
CC=clang
CXX=clang++

DARWIN=darwin17.3.0
PROTOC=protoc

IOS_SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
IPHONEOS_PLATFORM=`xcrun --sdk iphoneos --show-sdk-platform-path`
IPHONEOS_SYSROOT=`xcrun --sdk iphoneos --show-sdk-path`
IPHONESIMULATOR_PLATFORM=`xcrun --sdk iphonesimulator --show-sdk-platform-path`
IPHONESIMULATOR_SYSROOT=`xcrun --sdk iphonesimulator --show-sdk-path`

MIN_SDK_VERSION=8.3
STDLIB=libc++
SILENCED_WARNINGS="-Wno-unused-local-typedef -Wno-unused-function"

COMMON_FLAGS="-DNDEBUG -g -O0 -pipe -fPIC -fcxx-exceptions -miphoneos-version-min=${MIN_SDK_VERSION}"
#COMMON_FLAGS="-Os -gdwarf-2 -pipe -fPIC -fcxx-exceptions -Werror=partial-availability -fembed-bitcode -miphoneos-version-min=${MIN_SDK_VERSION}"
LIBS="-lc++ -lc++abi"


ARCHS=(armv7 armv7s arm64 i386 x86_64)
HOSTS=(armv7 armv7s arm i386 x86_64)

BUILD_DIR=$PWD_DIR/build/ios
mkdir -p $BUILD_DIR 2>/dev/null
#Build for all the architectures
for (( i=0; i<${#ARCHS[@]}; i++ )); do
#for (( i=0; i<1; i++ )); do
	make distclean

	ARCH=${ARCHS[$i]}

	CFLAGS="$COMMON_FLAGS -arch $ARCH"
	CXXFLAGS="${CFLAGS} -std=c++11 -stdlib=${STDLIB}"
	LDFLAGS="-stdlib=${STDLIB} -arch $ARCH -miphoneos-version-min=${MIN_SDK_VERSION}"

	echo "$ARCH"|grep 'arm' >/dev/null
	if [ $? -eq 0 ]; then
		./configure --host=${HOSTS[$i]}-apple-${DARWIN} \
			--with-protoc=${PROTOC} \
			--disable-shared \
			--prefix=${PREFIX} \
			--enable-cross-compile \
			"CC=${CC}" "CXX=${CXX}" \
			"CFLAGS=${CFLAGS} -isysroot ${IPHONEOS_SYSROOT}" \
			"CXXFLAGS=${CXXFLAGS} -isysroot ${IPHONEOS_SYSROOT}" \
			LDFLAGS="${LDFLAGS}" "LIBS=${LIBS}"
	else
		./configure --host=${HOSTS[$i]}-apple-darwin \
			--with-protoc=${PROTOC} \
			--disable-shared \
			--prefix=${PREFIX} \
			--enable-cross-compile \
			"CC=${CC}" "CXX=${CXX}" \
			"CFLAGS=${CFLAGS} -isysroot ${IPHONESIMULATOR_SYSROOT}" \
			"CXXFLAGS=${CXXFLAGS} -isysroot ${IPHONESIMULATOR_SYSROOT}" \
			LDFLAGS="${LDFLAGS} -L${IPHONESIMULATOR_SYSROOT}/usr/lib/" \
			"LIBS=${LIBS}"
	fi

	#export CFLAGS="-arch $ARCH -pipe -Os -gdwarf-2 -isysroot $XCODE/Platforms/${PLATFORMS[$i]}.platform/Developer/SDKs/${SDK[$i]}.sdk -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode -Werror=partial-availability"
	#export LDFLAGS="-arch $ARCH -isysroot $XCODE_DIR/Platforms/${PLATFORMS[$i]}.platform/Developer/SDKs/${SDK[$i]}.sdk"
	#if [ "${PLATFORMS[$i]}" = "iPhoneSimulator" ]; then
	#	export CXXFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
	#fi
	
	

	#./configure --host="${HOSTS[$i]}-apple-darwin" \
	#	--with-protoc=protoc \
	#	--enable-cross-compile \
	#	"CFLAGS=$CFLAGS" \
	#	"CXXFLAGS=${CFLAGS}" \
	#	LDFLAGS="-arch armv7 -miphoneos-version-min=${MIN_SDK_VERSION} -stdlib=libc++" \
	#	"LIBS=${LIBS}"

	#./configure	--host="${HOSTS[$i]}-apple-darwin" \
	#		--with-protoc=protoc LIBS="-lc -llog" \
	#		--enable-cross-compile \
	#		--enable-static \
	#		--enable-shared 

	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the configure program"
		cd "$PWD_DIR"
		exit $EXITCODE
	fi

	make -j $(sysctl -n hw.logicalcpu_max)
	EXITCODE=$?
	if [ $EXITCODE -ne 0 ]; then
		echo "Error running the make program"
		cd "$PWD_DIR"
		exit $EXITCODE
	fi

	cp $PB_DIR/src/.libs/libprotobuf-lite.a $BUILD_DIR/libprotobuf-lite_$ARCH.a
	cp $PB_DIR/src/.libs/libprotobuf.a $BUILD_DIR/libprotobuf_$ARCH.a
done

cd "$BUILD_DIR"
echo "create fat .a to dir: $BUILD_DIR"
lipo -create -output libprotobuf-lite.a libprotobuf-lite_*.a
#rm libprotobuf-lite-*.a
lipo -create -output libprotobuf.a libprotobuf_*.a
#rm libprotobuf-*.a

