#
# Makefile
# WARNING: relies on invocation setting current working directory to Makefile location
# This is done in .vscode/task.json
#
PROJECT				?= lvgl
MAKEFLAGS			:= -j $(shell nproc)
SRC_EXT				:= c
CXXSRC_EXT			:= cpp
OBJ_EXT				:= o
CXXOBJ_EXT			:= cpp.o
CC					?= gcc
CXX					?= g++

WORKING_DIR			:= ./build
BUILD_DIR			:= $(WORKING_DIR)/obj
BIN_DIR				:= $(WORKING_DIR)/bin
UI_DIR				:= ui
LVGL_DIR_NAME		?= ./3rd/lvgl/
LVGL_DIR			?= ${shell pwd}
EXCLUDE_DIR			:= */\.* $(LVGL_DIR)/$(LVGL_DIR_NAME)/tests $(LVGL_DIR)/$(LVGL_DIR_NAME)/env_support
EXCLUDE_DIR			+= $(LVGL_DIR)/3rd/media-server $(LVGL_DIR)/3rd/opencv-4.7.0
# EXCLUDE_DIR			+= $(LVGL_DIR)/$(LVGL_DIR_NAME)/examples

WARNINGS				:= -Wall -Wextra \
						-Wshadow -Wundef -Wmaybe-uninitialized -Wmissing-prototypes -Wno-discarded-qualifiers \
						-Wno-unused-function -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized \
						-Wno-unused-parameter -Wno-missing-field-initializers -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default  \
						-Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered -Wdeprecated  \
						-Wempty-body -Wshift-negative-value -Wstack-usage=2048 \
						-Wtype-limits -Wsizeof-pointer-memaccess -Wpointer-arith

CFLAGS				:= -O2 -g $(WARNINGS)
CXXFLAGS			:= -O2 -g

# LDFLAGS				:= -static

# Add simulator define to allow modification of source
DEFINES				:= -D SIMULATOR=1 -D LV_BUILD_TEST=0

# Include simulator inc folder first so lv_conf.h from custom UI can be used instead
INC					:= -I./ui/simulator/inc/ -I./ -I./3rd/ -I./3rd/lvgl/ 
INC					+= -I./3rd/ffmpeg/include -I./3rd/x264/include -I./3rd/x265/include -I./3rd/SDL2/include -I./3rd/libiconv/include
INC					+= -I./3rd/opencv/include/opencv4
LDLIBS				+= -L./3rd/ffmpeg/x86_64 -lavformat -lavcodec -lavutil -lswscale -lswresample
LDLIBS				+= -L./3rd/x264/x86_64 -lx264 -L./3rd/x265/x86_64 -lx265
LDLIBS				+= -L./3rd/SDL2/x86_64 -lSDL2 -L./3rd/libiconv/x86_64 -liconv
LDLIBS				+= -L./3rd/opencv/x86_64 -lopencv_core -lopencv_video -lopencv_videoio -lopencv_stitching -lopencv_photo -lopencv_objdetect -lopencv_ml
LDLIBS				+= -lopencv_imgproc -lopencv_imgcodecs -lopencv_highgui -lopencv_gapi -lopencv_features2d -lopencv_calib3d
LDLIBS				+= -lopencv_dnn -lopencv_flann
LDLIBS				+= -ldl -lcrypt -lm -lz -lpthread

BIN					:= $(BIN_DIR)/demo

# Automatically include all source files
CSRCS				:= $(patsubst %,-not -path '%/*',${EXCLUDE_DIR})
CSRCS				:= $(shell find $(LVGL_DIR) -type f -name '*.c' $(CSRCS))
OBJECTS				:= $(patsubst $(LVGL_DIR)%,$(BUILD_DIR)/%,$(CSRCS:.$(SRC_EXT)=.$(OBJ_EXT)))

CXXSRCS				:= $(patsubst %,-not -path '%/*',${EXCLUDE_DIR})
CXXSRCS				:= $(shell find $(LVGL_DIR) -type f -name '*.cpp' $(CXXSRCS))
CXXOBJECTS			:= $(patsubst $(LVGL_DIR)%,$(BUILD_DIR)/%,$(CXXSRCS:.$(CXXSRC_EXT)=.$(CXXOBJ_EXT)))

all: default

$(BUILD_DIR)/%.$(OBJ_EXT): $(LVGL_DIR)/%.$(SRC_EXT)
	@echo 'Building c project file: $<'
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $(INC) $(DEFINES) -c -o "$@" "$<"

$(BUILD_DIR)/%.$(CXXOBJ_EXT): $(LVGL_DIR)/%.$(CXXSRC_EXT)
	@echo 'Building cxx project file: $<'
	@mkdir -p $(dir $@)
	@$(CXX) $(CXXFLAGS) $(INC) $(DEFINES) -c -o "$@" "$<"

default: $(OBJECTS) $(CXXOBJECTS)
	@mkdir -p $(BIN_DIR)
	$(CXX) -o $(BIN) $(OBJECTS) $(CXXOBJECTS) $(LDFLAGS) ${LDLIBS}

clean:
	rm -rf $(WORKING_DIR)

install: ${BIN}
	install -d ${DESTDIR}/usr/lib/${PROJECT}/bin
	install $< ${DESTDIR}/usr/lib/${PROJECT}/bin/