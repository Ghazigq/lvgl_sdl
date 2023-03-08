#
# Makefile
# WARNING: relies on invocation setting current working directory to Makefile location
# This is done in .vscode/task.json
#
PROJECT				?= lvgl
MAKEFLAGS			:= -j $(shell nproc)
SRC_EXT				:= c
OBJ_EXT				:= o
CC					?= gcc

WORKING_DIR			:= ./build
BUILD_DIR			:= $(WORKING_DIR)/obj
BIN_DIR				:= $(WORKING_DIR)/bin
UI_DIR				:= ui
LVGL_DIR_NAME		?= ./3rd/lvgl/
LVGL_DIR			?= ${shell pwd}
EXCLUDE_DIR			:= */\.* $(LVGL_DIR)/$(LVGL_DIR_NAME)/tests $(LVGL_DIR)/$(LVGL_DIR_NAME)/env_support
EXCLUDE_DIR			+= $(LVGL_DIR)/3rd/media-server
# EXCLUDE_DIR			+= $(LVGL_DIR)/$(LVGL_DIR_NAME)/examples

WARNINGS				:= -Wall -Wextra \
						-Wshadow -Wundef -Wmaybe-uninitialized -Wmissing-prototypes -Wno-discarded-qualifiers \
						-Wno-unused-function -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized \
						-Wno-unused-parameter -Wno-missing-field-initializers -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default  \
						-Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered -Wdeprecated  \
						-Wempty-body -Wshift-negative-value -Wstack-usage=2048 \
						-Wtype-limits -Wsizeof-pointer-memaccess -Wpointer-arith

CFLAGS				:= -O2 -g $(WARNINGS)

# Add simulator define to allow modification of source
DEFINES				:= -D SIMULATOR=1 -D LV_BUILD_TEST=0

# Include simulator inc folder first so lv_conf.h from custom UI can be used instead
INC					:= -I./ui/simulator/inc/ -I./ -I./3rd/ -I./3rd/lvgl/ 
INC					+= -I./3rd/ffmpeg/include -I./3rd/x264/include -I./3rd/x265/include -I./3rd/SDL2/include -I./3rd/libiconv/include
LDLIBS				+= -L./3rd/ffmpeg/x86_64 -lavformat -lavcodec -lavutil -lswscale -lswresample
LDLIBS				+= -L./3rd/x264/x86_64 -lx264 -L./3rd/x265/x86_64 -lx265
LDLIBS				+= -L./3rd/SDL2/x86_64 -lSDL2 -L./3rd/libiconv/x86_64 -liconv
LDLIBS				+= -ldl -lcrypt -lm -lz -lpthread -lstdc++

BIN					:= $(BIN_DIR)/demo

COMPILE				= $(CC) $(CFLAGS) $(INC) $(DEFINES)

# Automatically include all source files
CSRCS				:= $(patsubst %,-not -path '%/*',${EXCLUDE_DIR})
CSRCS				:= $(shell find $(LVGL_DIR) -type f -name '*.c' $(CSRCS))
OBJECTS				:= $(patsubst $(LVGL_DIR)%,$(BUILD_DIR)/%,$(CSRCS:.$(SRC_EXT)=.$(OBJ_EXT)))

all: default

$(BUILD_DIR)/%.$(OBJ_EXT): $(LVGL_DIR)/%.$(SRC_EXT)
	@echo 'Building project file: $<'
	@mkdir -p $(dir $@)
	@$(COMPILE) -c -o "$@" "$<"

default: $(OBJECTS)
	@mkdir -p $(BIN_DIR)
	$(CC) -o $(BIN) $(OBJECTS) $(LDFLAGS) ${LDLIBS}

clean:
	rm -rf $(WORKING_DIR)

install: ${BIN}
	install -d ${DESTDIR}/usr/lib/${PROJECT}/bin
	install $< ${DESTDIR}/usr/lib/${PROJECT}/bin/