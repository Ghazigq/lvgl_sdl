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
lvgl-cflags-y += -D SIMULATOR=1 -D LV_BUILD_TEST=0 -I3rd -I3rd/lvgl -I3rd/x86_64/include

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
bin_src-cflags-y := -I. -Iui/simulator/inc -I3rd -I3rd/x86_64/include -I3rd/x86_64/include/opencv4
bin_src-ldflags-y := -static -L./3rd/x86_64/lib -L./3rd/x86_64/lib/opencv4/3rdparty \
					-lopencv_flann -lopencv_ml -lopencv_photo -lopencv_dnn -lopencv_features2d -lopencv_videoio -lopencv_imgcodecs -lopencv_calib3d \
					-lopencv_highgui -lopencv_objdetect -lopencv_stitching -lopencv_video -lopencv_gapi -lopencv_imgproc -lopencv_core \
					-llibjpeg-turbo -llibtiff -llibwebp -llibopenjp2 -lIlmImf -lippiw -lippicv -llibprotobuf -lquirc -littnotify -lade -lpng -lpng16 \
					-lavdevice -lavfilter -lavformat -lavcodec -lavutil -lswscale -lswresample -lpostproc -lx264 -lx265 -lfdk-aac \
					-llvgl -llv_drivers \
					-lSDL2 -liconv \
					-ldl -lcrypt -lm -lz -lpthread

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
