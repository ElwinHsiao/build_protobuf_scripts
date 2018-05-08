APP_STL := gnustl_static # gnustl_shared 
#NDK_TOOLCHAIN_VERSION := 4.9
# APP_ABI := all
APP_ABI := armeabi armeabi-v7a x86 x86_64 arm64-v8a
APP_CPPFLAGS := -frtti # -std=c++11
#LIBCXX_FORCE_REBUILD := true
APP_PLATFORM:=android-15
#NDK_DEBUG:=1
APP_MODULES = protobuf-lite	# the ndk won't generate .a if no one depends on it, so there add a dummy APP_MODULES