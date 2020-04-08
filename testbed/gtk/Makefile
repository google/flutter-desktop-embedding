include ../linux/app_configuration.mk

GTK_BINARY_NAME=$(BINARY_NAME)_gtk

# Default build type.
BUILD=debug

FLUTTER_MANAGED_DIR=../linux/flutter
FLUTTER_EPHEMERAL_DIR=$(FLUTTER_MANAGED_DIR)/ephemeral

# Configuration provided via flutter tool.
FLUTTER_CONFIG_FILE=$(FLUTTER_EPHEMERAL_DIR)/generated_config.mk
include $(FLUTTER_CONFIG_FILE)

# Dependency locations
FLUTTER_APP_DIR=$(CURDIR)/..
FLUTTER_APP_BUILD_DIR=$(FLUTTER_APP_DIR)/build
ENGINE_BUILD_DIR=$(FLUTTER_ENGINE)/out/$(LOCAL_ENGINE)

OUT_DIR=$(FLUTTER_APP_BUILD_DIR)/linux
OBJ_DIR=$(OUT_DIR)/obj_gtk/$(BUILD)

# Libraries
FLUTTER_LIB_NAME=flutter_linux_gtk
FLUTTER_LIB=$(ENGINE_BUILD_DIR)/lib$(FLUTTER_LIB_NAME).so

# Bundle structure
BUNDLE_OUT_DIR=$(OUT_DIR)/$(BUILD)
BUNDLE_LIB_DIR=$(BUNDLE_OUT_DIR)/lib

BIN_OUT=$(BUNDLE_OUT_DIR)/$(GTK_BINARY_NAME)
FLUTTER_LIB_OUT=$(BUNDLE_LIB_DIR)/$(notdir $(FLUTTER_LIB))
ALL_LIBS_OUT=$(FLUTTER_LIB_OUT)

# Use abspath for extra sources, which may also contain relative paths (see
# note above about WRAPPER_ROOT).
SOURCES=main.cc

# Headers
INCLUDE_DIRS=$(ENGINE_BUILD_DIR)

# Build settings
ifneq ($(strip $(SYSTEM_LIBRARIES)),)
EXTRA_CPPFLAGS+=$(patsubst -I%,-isystem%,$(shell pkg-config --cflags $(SYSTEM_LIBRARIES)))
EXTRA_LDFLAGS+=$(shell pkg-config --libs $(SYSTEM_LIBRARIES))
endif
CXX=clang++
CPPFLAGS.release=-DNDEBUG
CPPFLAGS.profile=$(CPPFLAGS.release)
CXXFLAGS.release=-O2
CXXFLAGS.profile=$(CXXFLAGS.release)
CXXFLAGS=-std=c++14 -Wall -Werror $(CXXFLAGS.$(BUILD)) $(EXTRA_CXXFLAGS)
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS)) \
	$(CPPFLAGS.$(BUILD)) $(EXTRA_CPPFLAGS)
LDFLAGS=-L$(BUNDLE_LIB_DIR) \
	-l$(FLUTTER_LIB_NAME) \
	$(EXTRA_LDFLAGS) \
	-Wl,-rpath=\$$ORIGIN/lib

# Intermediate files.
OBJ_FILES=$(SOURCES:%.cc=$(OBJ_DIR)/%.o)
DEPENDENCY_FILES=$(OBJ_FILES:%.o=%.d)

# Targets

.PHONY: all
all: $(BIN_OUT)

$(BIN_OUT): $(OBJ_FILES) $(ALL_LIBS_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OBJ_FILES) $(LDFLAGS) -o $@

$(FLUTTER_LIB_OUT): $(FLUTTER_LIB)
	mkdir -p $(@D)
	cp $< $@

-include $(DEPENDENCY_FILES)

$(OBJ_DIR)/%.o : %.cc
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -c $< -o $@

.PHONY: clean
clean:
	rm $(BIN_OUT) $(FLUTTER_LIB_OUT)
