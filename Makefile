################################################################################
# Hangzhou Meari Technology Co.,Ltd.
# author: gq
# date: 2021-12-31
################################################################################

# please export this variable in your bashrc file, try to use your nickname

ifeq ($(V),)
	Q := @
endif

VERSION_EXTRA_STRING :=$(shell date --iso-8601=ns)


################################################################################
# configuration file
################################################################################
-include .config

# Generated Variables
ALL_GENERATED_CONFIGS := $(shell [ -e .config ] && grep ^CONFIG .config \
	| sed 's/ /\\ /g' | sed 's/"/\\"/g' | sed 's/\(CONFIG_.*\)=\(.*\)/\1=\2/g')

ALL_CONFIG_NAME := $(shell [ -e .config ] && grep ^CONFIG .config | sed 's/\(CONFIG_.*\)=.*/\1/g')

# init variables
PROJECT_SOURCE_DIR := .
CFLAGS :=
LDFLAGS :=
PROJECT_BUILD_DIR ?= $(PROJECT_SOURCE_DIR)/build
PROJECT_INSTALL_DIR ?= $(PROJECT_SOURCE_DIR)/install

ifneq ($(CONFIG_BUILD_DIR),)
	PROJECT_BUILD_DIR := $(subst ",,$(CONFIG_BUILD_DIR))
endif

ifneq ($(CONFIG_INSTALL_DIR),)
	PROJECT_INSTALL_DIR := $(subst ",,$(CONFIG_INSTALL_DIR))
endif

ifeq ($(CONFIG_PLATFORM_NAME),)
	CONFIG_PLATFORM_NAME := $(shell uname -s)_$(shell uname -m)
endif

ifneq ($(CONFIG_LITEOS_PREFIX),)
	LITEOSTOPDIR ?= $(subst ",,$(CONFIG_LITEOS_PREFIX))
	include $(LITEOSTOPDIR)/config.mk

	CFLAGS := $(LITEOS_CFLAGS)
endif

CROSS_COMPILE :=$(subst ",,$(CONFIG_CROSS_COMPILE_PREFIX))
CROSS_COMPILE_SUFFIX :=$(subst ",,$(CONFIG_CROSS_COMPILE_SUFFIX))
TEST_RUN_PREFIX :=$(subst ",,$(CONFIG_TEST_RUN_PREFIX))

CC  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
AR  := $(CROSS_COMPILE)$(CROSS_COMPILE_SUFFIX)ar
RM  := rm -rf
COPY := cp -rf
MOVE := mv
MKDIR := mkdir -p
MAKE := make --no-print-directory

#_ALL_GENERATED_CONFIGS := $(filter-out %=n,$(ALL_GENERATED_CONFIGS))
_ALL_GENERATED_CONFIGS := $(subst \ ,'@',$(_ALL_GENERATED_CONFIGS))
_ALL_GENERATED_CONFIGS := $(_ALL_GENERATED_CONFIGS:%=-D%)
_ALL_GENERATED_CONFIGS := $(subst '@',\ ,$(_ALL_GENERATED_CONFIGS))

CFLAGS += -Wall -O2 -g
CFLAGS += -ffunction-sections -fdata-sections -Wno-unused-variable -Wno-unused-function -Wno-unknown-pragmas -Wno-unused-result
ifeq ($(CONFIG_PLAT_WINDOWS),y)
CFLAGS += -DOS_WINDOWS -D_WIN32_WINNT=0x0600
else
CFLAGS += -DOS_LINUX
endif
CFLAGS += $(subst ",,$(CONFIG_EXTRA_CFLAGS))
#CFLAGS += $(_ALL_GENERATED_CONFIGS:%=-D%)

LDFLAGS += $(subst ",,$(CONFIG_EXTRA_LDFLAGS))

VERSION_MAJOR    := $(shell expr $(shell git log --oneline | wc -l) / 65535 + 1)
VERSION_MINOR    := $(shell expr $(shell git log --oneline | wc -l) / 255)
VERSION_REVISION := $(shell expr $(shell git log --oneline | wc -l) % 255)
VERSION_EXTRA    := 0

GENERATE_GIT_INFO_H     := $(PROJECT_BUILD_DIR)/git_info.h
GENERATE_VERSION_H      := $(PROJECT_BUILD_DIR)/version.h
CFLAGS  += -I$(PROJECT_BUILD_DIR)

LDFLAGS += -Wl,--gc-sections
LDFLAGS += -L$(PROJECT_BUILD_DIR)

export PROJECT_BUILD_DIR
export PROJECT_INSTALL_DIR
export CFLAGS
export CXXFLAGS
export LDFLAGS
export LDXXFLAGS
export CC
export CXX
export AR
export MAKE
export RM
export MKDIR
export CROSS_COMPILE
export TEST_RUN_PREFIX

# export all config name
# $(foreach conf,$(ALL_CONFIG_NAME), $(eval export $(conf)))

################################################################################
# build functions
################################################################################

# static and dynamic library build rule
define make-library-target

ifeq ($(CONFIG_PLAT_WINDOWS),y)
	_$1_output := $1.dll
else
	_$1_output := lib$1.a
	_$1_output_so := lib$1.so
endif

_$1_objs := $$($1-objs-y:%.c=$$(PROJECT_BUILD_DIR)/%.c.o)
_$1_objs := $$(_$1_objs:%.cpp=$$(PROJECT_BUILD_DIR)/%.cpp.o)
_$1_deps := $$(_$1_objs:%.o=$$(PROJECT_BUILD_DIR)/%.d)
_$1_c_objs := $$(filter %.c.o,$$(_$1_objs))
_$1_cc_objs := $$(filter %.cpp.o,$$(_$1_objs))

-include $$(_$1_deps)

$1: $$(_$1_c_objs) $$(_$1_cc_objs)
	$(Q)echo "Generate $$(_$1_output)"
	$(Q)$(MKDIR) $$(PROJECT_BUILD_DIR)
	$(Q)$$(AR) crs $$(PROJECT_BUILD_DIR)/$$(_$1_output) $$^
ifneq ($(CONFIG_PLAT_WINDOWS),y)
ifneq ($(CONFIG_NO_SHARED),y)
	$(Q)echo "Generate $$(_$1_output_so)"
ifeq ($$(_$1_cc_objs),)
	$(Q)$$(CC) -shared -o $$(PROJECT_BUILD_DIR)/$$(_$1_output_so) $$^
else
	$(Q)$$(CXX) -shared -o $$(PROJECT_BUILD_DIR)/$$(_$1_output_so) $$^
endif
endif
endif

$$(_$1_c_objs):$$(PROJECT_BUILD_DIR)/%.c.o:%.c
	$(Q)echo "  CC $$(patsubst %.c,%.c.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
ifneq ($(CONFIG_PLAT_WINDOWS),y)
	$(Q)$$(CC) -fPIC $$(CFLAGS) -std=gnu99 $$($1-cflags-y) -c $$< -o $$@ -MMD
else
	$(Q)$$(CC) $$(CFLAGS) -std=gnu99 $$($1-cflags-y) -c $$< -o $$@ -MMD
endif

$$(_$1_cc_objs):$$(PROJECT_BUILD_DIR)/%.cpp.o:%.cpp
	$(Q)echo "  CXX $$(patsubst %.cpp,%.cpp.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
ifneq ($(CONFIG_PLAT_WINDOWS),y)
	$(Q)$$(CXX) -fPIC $$(CFLAGS) -std=c++11 $$($1-cflags-y) -c $$< -o $$@ -MMD
else
	$(Q)$$(CXX) $$(CFLAGS) -std=c++11 $$($1-cflags-y) -c $$< -o $$@ -MMD
endif
endef

# test build rule
define make-test-target

_$1_objs := $$($1-objs-y:%.c=$$(PROJECT_BUILD_DIR)/%.c.o)
_$1_objs := $$(_$1_objs:%.cpp=$$(PROJECT_BUILD_DIR)/%.cpp.o)
_$1_deps := $$(_$1_objs:%.o=$$(PROJECT_BUILD_DIR)/%.d)
_$1_c_objs := $$(filter %.c.o,$$(_$1_objs))
_$1_cc_objs := $$(filter %.cpp.o,$$(_$1_objs))

-include $$(_$1_deps)

$1: $$(_$1_c_objs) $$(_$1_cc_objs)
	$(Q)echo "Build $$@"
ifeq ($$(_$1_cc_objs),)
	$(Q)$$(CC) $$^ $$(LDFLAGS) $$($1-ldflags-y) -o $$(PROJECT_BUILD_DIR)/$$@
else
	$(Q)$$(CXX) $$^ $$(LDFLAGS) $$($1-ldflags-y) -o $$(PROJECT_BUILD_DIR)/$$@
endif
ifeq ($(IF_TEST_RUN),TRUE)
	$(Q)echo ------Test Start------
	$(Q)$$(TEST_RUN_PREFIX) $$(PROJECT_BUILD_DIR)/$$@
	$(Q)echo ------Test OK------
endif

$$(_$1_c_objs):$$(PROJECT_BUILD_DIR)/%.c.o:%.c
	$(Q)echo "  CC $$(patsubst %.c,%.c.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
	$(Q)$$(CC) $$(CFLAGS) -std=gnu99 $$($1-cflags-y) -c $$< -o $$@ -MMD

$$(_$1_cc_objs):$$(PROJECT_BUILD_DIR)/%.cc.o:%.cc
	$(Q)echo "  CXX $$(patsubst %.cc,%.cc.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
	$(Q)$$(CXX) $$(CFLAGS) -std=c++11 $$($1-cflags-y) -c $$< -o $$@ -MMD
endef

# binary build rule
define make-bin-target

_$1_objs := $$($1-objs-y:%.c=$$(PROJECT_BUILD_DIR)/%.c.o)
_$1_objs := $$(_$1_objs:%.cpp=$$(PROJECT_BUILD_DIR)/%.cpp.o)
_$1_deps := $$(_$1_objs:%.o=$$(PROJECT_BUILD_DIR)/%.d)
_$1_c_objs := $$(filter %.c.o,$$(_$1_objs))
_$1_cc_objs := $$(filter %.cpp.o,$$(_$1_objs))

-include $$(_$1_deps)
$1: $$(_$1_c_objs) $$(_$1_cc_objs)
	$(Q)echo "Build $$@"
ifeq ($$(_$1_cc_objs),)
	$(Q)$$(CC) $$^ $$(LDFLAGS) $$($1-ldflags-y) -o $$(PROJECT_BUILD_DIR)/$$@
else
	$(Q)$$(CXX) $$^ $$(LDFLAGS) $$($1-ldflags-y) -o $$(PROJECT_BUILD_DIR)/$$@
endif

$$(_$1_c_objs):$$(PROJECT_BUILD_DIR)/%.c.o:%.c
	$(Q)echo "  CC $$(patsubst %.c,%.c.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
	$(Q)$$(CC) $$(CFLAGS) -std=gnu99 $$($1-cflags-y) -c $$< -o $$@ -MMD

$$(_$1_cc_objs):$$(PROJECT_BUILD_DIR)/%.cpp.o:%.cpp
	$(Q)echo "  CXX $$(patsubst %.cpp,%.cpp.o,$$<)"
	$(Q)$(MKDIR) `dirname $$@`
	$(Q)$$(CXX) $$(CFLAGS) -std=c++11 $$($1-cflags-y) -c $$< -o $$@ -MMD
endef

################################################################################
# library source
################################################################################

-include src_objs.mk

export PROJECT_INSTALL_DIR_BASE := $(PROJECT_INSTALL_DIR)
export PROJECT_INSTALL_DIR_EXTRA := $(install-package_prefix-y)
export PROJECT_INSTALL_DIR := $(PROJECT_INSTALL_DIR)

################################################################################
# build rule
################################################################################

.PHONY: all clean distclean install test git_info_gen version_gen $(lib-y) $(test-y) targets all_tests

all:
ifneq (.config, $(wildcard .config))
	$(Q)echo configure file .config does not exist, please configure it.
else
	$(Q)$(MAKE) -f Makefile git_info_gen
	$(Q)$(MAKE) -f Makefile version_gen
	$(Q)echo Building targets ...
	$(Q)$(MAKE) -f Makefile targets
endif

git_info_gen:
ifeq ($(CONFIG_PLAT_WINDOWS),y)
	sh $(PROJECT_SOURCE_DIR)/version/gen_git_info.sh --file=$(GENERATE_GIT_INFO_H)
else
	$(PROJECT_SOURCE_DIR)/version/gen_git_info.sh --file=$(GENERATE_GIT_INFO_H)
endif

version_gen:
# ifeq ($(CONFIG_PLAT_WINDOWS),y)
# 	sh $(PROJECT_SOURCE_DIR)/version/gen_version.sh --file=$(GENERATE_VERSION_H)
# else
# 	$(PROJECT_SOURCE_DIR)/version/gen_version.sh --file=$(GENERATE_VERSION_H)
# endif
ifneq ($(GENERATE_VERSION_H), $(wildcard $(GENERATE_VERSION_H)))
	$(Q)echo Generating $(notdir $(GENERATE_VERSION_H)) ...
	$(Q)$(MKDIR) `dirname $(GENERATE_VERSION_H)`
	$(Q)echo "/* This is auto-generated file, please do not modify it. */" > $(GENERATE_VERSION_H)
	$(Q)echo "#ifndef _PPS_VERSION_H" >> $(GENERATE_VERSION_H)
	$(Q)echo "#define _PPS_VERSION_H" >> $(GENERATE_VERSION_H)
	$(Q)echo "" >> $(GENERATE_VERSION_H)
	$(Q)echo "#define VERSION_MAJOR $(VERSION_MAJOR)" >> $(GENERATE_VERSION_H)
	$(Q)echo "#define VERSION_MINOR $(VERSION_MINOR)" >> $(GENERATE_VERSION_H)
	$(Q)echo "#define VERSION_REVISION $(VERSION_REVISION)" >> $(GENERATE_VERSION_H)
	$(Q)echo "" >> $(GENERATE_VERSION_H)
	$(Q)echo "#endif /* _PPS_VERSION_H */" >> $(GENERATE_VERSION_H)
endif


targets: $(lib-y) $(bin-y)

distclean:
	-@$(RM) $(PROJECT_BUILD_DIR)
	-@$(RM) .config

clean:
	-@$(RM) $(PROJECT_BUILD_DIR)/*

install:
	$(Q)$(RM) $(PROJECT_INSTALL_DIR_BASE)
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/lib
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/doc
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/bin
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/include
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/example
	$(Q)for i in $(install-example-y); do $(COPY) $$i $(PROJECT_INSTALL_DIR)/example/; done && if [ x"$(install-example-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/example/*; fi
	$(Q)for i in $(install-include-y); do $(COPY) $$i $(PROJECT_INSTALL_DIR)/include/; done && if [ x"$(install-include-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/include/*; fi
	$(Q)for i in $(install-doc-y); do $(COPY) $$i $(PROJECT_INSTALL_DIR)/doc/; done && if [ x"$(install-doc-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/doc/*; fi
ifeq ($(CONFIG_PLAT_WINDOWS),y)
	$(Q)for i in $(install-lib-y); do $(COPY) $(PROJECT_BUILD_DIR)/$$i.dll $(PROJECT_INSTALL_DIR)/lib/; done && if [ x"$(install-lib-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/lib/*; fi
else
ifeq ($(CONFIG_NO_SHARED),y)
	$(Q)for i in $(install-lib-y); do $(COPY) $(PROJECT_BUILD_DIR)/lib$$i.a $(PROJECT_INSTALL_DIR)/lib/; done && if [ x"$(install-lib-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/lib/*; fi
else
	$(Q)$(MKDIR) $(PROJECT_INSTALL_DIR)/dylib
	$(Q)for i in $(install-lib-y); do $(COPY) $(PROJECT_BUILD_DIR)/lib$$i.a $(PROJECT_INSTALL_DIR)/lib/; done && if [ x"$(install-lib-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/lib/*; fi
	$(Q)for i in $(install-lib-y); do $(COPY) $(PROJECT_BUILD_DIR)/lib$$i*.so $(PROJECT_INSTALL_DIR)/dylib/; done && if [ x"$(install-lib-y)" != x ]; then chmod 0644 $(PROJECT_INSTALL_DIR)/dylib/*; fi
endif
endif
	$(Q)for i in $(install-libdeps-y); do if [ -f $$i ]; then $(COPY) $$i $(PROJECT_INSTALL_DIR)/lib/; chmod 0644 $(PROJECT_INSTALL_DIR)/lib/`basename $$i` ; fi; done
	$(Q)for i in $(install-bin-y); do if [ -f $(PROJECT_BUILD_DIR)/$$i ]; then $(COPY) $(PROJECT_BUILD_DIR)/$$i $(PROJECT_INSTALL_DIR)/bin/; chmod 0755 $(PROJECT_INSTALL_DIR)/bin/$$i; fi; done
ifeq ($(CONFIG_PLAT_WINDOWS),y)
	$(Q)for i in $(install-bin-y); do if [ -f $(PROJECT_BUILD_DIR)/$$i ]; then $(MOVE) $(PROJECT_INSTALL_DIR)/bin/$$i $(PROJECT_INSTALL_DIR)/bin/$$i.exe; fi; done
endif
	$(Q)for i in $(install-changelog-y); do $(COPY) $$i $(PROJECT_INSTALL_DIR)/doc/ && chmod 0644 $(PROJECT_INSTALL_DIR)/doc/`basename $$i`; done
ifeq ($(CONFIG_PLAT_WINDOWS),y)
	$(Q)tar czf $(PROJECT_INSTALL_DIR)/$(PROJECT_INSTALL_DIR_EXTRA).tar.gz $(PROJECT_INSTALL_DIR)/bin $(PROJECT_INSTALL_DIR)/doc $(PROJECT_INSTALL_DIR)/example $(PROJECT_INSTALL_DIR)/include $(PROJECT_INSTALL_DIR)/lib
else
	$(Q)tar czf $(PROJECT_INSTALL_DIR)/$(PROJECT_INSTALL_DIR_EXTRA).tar.gz $(PROJECT_INSTALL_DIR)/bin $(PROJECT_INSTALL_DIR)/doc $(PROJECT_INSTALL_DIR)/dylib $(PROJECT_INSTALL_DIR)/example $(PROJECT_INSTALL_DIR)/include $(PROJECT_INSTALL_DIR)/lib
endif
# $(Q)tree $(PROJECT_INSTALL_DIR_BASE)


test:
	$(Q)make -f Makefile all
	$(Q)make -f Makefile all_tests

run:
	$(Q)make -f Makefile all
	$(Q)make -f Makefile all_tests IF_TEST_RUN=TRUE

all_tests: $(test-y)
ifneq ($(CONFIG_PLAT_WINDOWS),y)
ifneq ($(test-y),)
	cp $(patsubst %,$(PROJECT_BUILD_DIR)/%,$(test-y)) ${TFTPBOOT}
endif
endif

$(foreach it,$(lib-y),$(eval $(call make-library-target,$(it))))
$(foreach it,$(test-y),$(eval $(call make-test-target,$(it))))
$(foreach it,$(bin-y),$(eval $(call make-bin-target,$(it))))
