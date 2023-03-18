################################################################################
# library source
################################################################################

lib-y := lvgl lv_drivers

exclude_dir := 3rd/lvgl/tests 3rd/lvgl/env_support
lvgl-objs-y := $(patsubst %,-not -path '%/*',$(exclude_dir))
lvgl-objs-y := $(shell find 3rd/lvgl -type f -name '*.c' $(lvgl-objs-y))

lvgl-cflags-y := -Wextra -Wshadow -Wundef -Wmaybe-uninitialized -Wmissing-prototypes -Wno-discarded-qualifiers -Wno-error=strict-prototypes \
				-Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized -Wno-unused-parameter -Wno-missing-field-initializers \
				-Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default -Wreturn-type -Wmultichar -Wformat-security \
				-Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered \
				-Wdeprecated -Wempty-body -Wshift-negative-value -Wstack-usage=2048 -Wtype-limits -Wsizeof-pointer-memaccess -Wpointer-arith
lvgl-cflags-y += -D SIMULATOR=1 -D LV_BUILD_TEST=0 -I3rd -I3rd/lvgl -I3rd/$(CONFIG_ARCH_PATH)/include

exclude_dir := 
lv_drivers-objs-y := $(patsubst %,-not -path '%/*',$(exclude_dir))
lv_drivers-objs-y := $(shell find 3rd/lv_drivers -type f -name '*.c' $(lv_drivers-objs-y))
lv_drivers-cflags-y := $(lvgl-cflags-y)

################################################################################
# bin source
################################################################################

bin-y := bin_src

bin_src-objs-y := main.cpp
bin_src-objs-y += $(shell find ui -type f -name '*.c' -o -name '*.cpp')
bin_src-cflags-y := -I. -Iui/simulator/inc -I3rd -I3rd/lvgl -I3rd/$(CONFIG_ARCH_PATH)/include -I3rd/$(CONFIG_ARCH_PATH)/include/opencv4
ifeq ($(CONFIG_PLAT_WINDOWS),y)
bin_src-cflags-y  += -DOS_WINDOWS
bin_src-ldflags-y += $(PROJECT_BUILD_DIR)/lvgl.dll $(PROJECT_BUILD_DIR)/lv_drivers.dll
bin_src-ldflags-y += $(patsubst %,3rd/$(CONFIG_ARCH_PATH)/lib/lib%.a,avdevice avfilter avformat avcodec avutil swscale swresample postproc)
bin_src-ldflags-y += -L3rd/$(CONFIG_ARCH_PATH)/lib -lx264
bin_src-ldflags-y += $(patsubst %,3rd/$(CONFIG_ARCH_PATH)/lib/lib%.a,x265 fdk-aac jpeg png png16 \
					SDL2main SDL2)
bin_src-ldflags-y += -lpsapi -lshlwapi -lvfw32 -liconv -latomic -llzma -lmfuuid -lstrmiids -lz -lbz2 -lsecur32 -lws2_32 -lbcrypt -lm -lgcc_s -lgcc# ffmpeg
bin_src-ldflags-y += -lmingw32 -mwindows -ldxguid -ldxerr8 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid
else
bin_src-ldflags-y += $(PROJECT_BUILD_DIR)/liblvgl.a $(PROJECT_BUILD_DIR)/liblv_drivers.a
bin_src-ldflags-y += $(patsubst %,3rd/x86_64/lib/lib%.a,opencv_flann opencv_ml opencv_photo opencv_dnn opencv_features2d opencv_videoio opencv_imgcodecs opencv_calib3d \
					opencv_highgui opencv_objdetect opencv_stitching opencv_video opencv_gapi opencv_imgproc opencv_core \
					jpeg png png16 \
					avdevice avfilter avformat avcodec avutil swscale swresample postproc x264 x265 fdk-aac \
					SDL2 )
bin_src-ldflags-y += $(patsubst %,3rd/x86_64/lib/opencv4/3rdparty/lib%.a,libtiff libwebp libopenjp2 IlmImf ippiw ippicv libprotobuf quirc ittnotify ade)
bin_src-ldflags-y += -liconv -ldl -lcrypt -lm -lz -lpthread
endif

################################################################################
# test source
################################################################################

test-y := 

################################################################################
# install config
################################################################################

# only support *.tar.gz
install-package_prefix-y :=
install-lib-y :=
# not support sub directory
install-include-y :=


install-bin-y :=
install-example-y :=
install-changelog-y :=
install-doc-y :=
