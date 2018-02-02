LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := protobuf-lite

SOURCE_BASE := $(LOCAL_PATH)/../protobuf/src
SOURCE_DIR := $(SOURCE_BASE)/google/protobuf/
PROTO_SOURCE := $(shell cat $(LOCAL_PATH)/../lite_files.txt)
LOCAL_SRC_FILES := $(addprefix $(SOURCE_DIR),$(PROTO_SOURCE))
LOCAL_C_INCLUDES := $(SOURCE_BASE)


LOCAL_CFLAGS := -D GOOGLE_PROTOBUF_NO_RTTI=1 -DHAVE_PTHREAD
LOCAL_CPPFLAGS := -std=c++11
#LOCAL_C_INCLUDES += ${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/4.8/include
#LOCAL_LDLIBS += -lz -llog


include $(BUILD_STATIC_LIBRARY)
