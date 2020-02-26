
# Implicit rules won't match phony targets, so list plugin builds explicitly.
$(OUT_DIR)/libcolor_panel_plugin.so: | color_panel
$(OUT_DIR)/libfile_chooser_plugin.so: | file_chooser
$(OUT_DIR)/libmenubar_plugin.so: | menubar
$(OUT_DIR)/libsample_plugin.so: | sample
$(OUT_DIR)/liburl_launcher_fde_plugin.so: | url_launcher_fde
$(OUT_DIR)/libwindow_size_plugin.so: | window_size
