# Plugins to include in the build.
PLUGINS=\
	color_panel \
	file_chooser \
	menubar \
	sample \
	url_launcher_fde \
	window_size

# The name of each plugin library is the name of the plugin with _plugin
# appended.
FLUTTER_PLUGIN_LIB_NAMES=$(foreach plugin,$(PLUGINS),$(plugin)_plugin)
PLUGINS_DIR=$(FLUTTER_EPHEMERAL_DIR)/.plugin_symlinks

# Variables for use in the enclosing Makefile. Changes to these names are
# breaking changes.
PLUGIN_TARGETS=$(PLUGINS)
PLUGIN_LIBRARIES=$(foreach plugin,$(FLUTTER_PLUGIN_LIB_NAMES),$(OUT_DIR)/lib$(plugin).so)
PLUGIN_LDFLAGS=$(patsubst %,-l%,$(FLUTTER_PLUGIN_LIB_NAMES))
PLUGIN_CPPFLAGS=$(foreach plugin,$(PLUGINS),-I$(PLUGINS_DIR)/$(plugin)/linux)

# Targets

# Implicit rules won't match phony targets, so list plugin builds explicitly.
$(OUT_DIR)/libcolor_panel_plugin.so: | color_panel
$(OUT_DIR)/libfile_chooser_plugin.so: | file_chooser
$(OUT_DIR)/libmenubar_plugin.so: | menubar
$(OUT_DIR)/libsample_plugin.so: | sample
$(OUT_DIR)/liburl_launcher_fde_plugin.so: | url_launcher_fde
$(OUT_DIR)/libwindow_size_plugin.so: | window_size

.PHONY: $(PLUGINS)
$(PLUGINS):
	make -C $(PLUGINS_DIR)/$@/linux \
		OUT_DIR=$(OUT_DIR) \
		FLUTTER_EPHEMERAL_DIR="$(abspath $(FLUTTER_EPHEMERAL_DIR))"
