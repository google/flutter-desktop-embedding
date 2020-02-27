# Plugins to include in the build.
GENERATED_PLUGINS=\
	color_panel \
	file_chooser \
	menubar \
	sample \
	url_launcher_fde \
	window_size \

GENERATED_PLUGINS_DIR=flutter/ephemeral/.plugin_symlinks
# A plugin library name plugin name with _plugin appended.
GENERATED_PLUGIN_LIB_NAMES=$(foreach plugin,$(GENERATED_PLUGINS),$(plugin)_plugin)

# Variables for use in the enclosing Makefile. Changes to these names are
# breaking changes.
PLUGIN_TARGETS=$(GENERATED_PLUGINS)
PLUGIN_LIBRARIES=$(foreach plugin,$(GENERATED_PLUGIN_LIB_NAMES),\
	$(OUT_DIR)/lib$(plugin).so)
PLUGIN_LDFLAGS=$(patsubst %,-l%,$(GENERATED_PLUGIN_LIB_NAMES))
PLUGIN_CPPFLAGS=$(foreach plugin,$(GENERATED_PLUGINS),\
	-I$(GENERATED_PLUGINS_DIR)/$(plugin)/linux)

# Targets

# Implicit rules don't match phony targets, so list plugin builds explicitly.
$(OUT_DIR)/libcolor_panel_plugin.so: | color_panel
$(OUT_DIR)/libfile_chooser_plugin.so: | file_chooser
$(OUT_DIR)/libmenubar_plugin.so: | menubar
$(OUT_DIR)/libsample_plugin.so: | sample
$(OUT_DIR)/liburl_launcher_fde_plugin.so: | url_launcher_fde
$(OUT_DIR)/libwindow_size_plugin.so: | window_size

.PHONY: $(GENERATED_PLUGINS)
$(GENERATED_PLUGINS):
	make -C $(GENERATED_PLUGINS_DIR)/$@/linux \
		OUT_DIR=$(OUT_DIR) \
		FLUTTER_EPHEMERAL_DIR="$(abspath flutter/ephemeral)"
