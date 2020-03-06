list(APPEND FLUTTER_PLUGIN_LIST
  color_panel
  file_chooser
  url_launcher_fde
  menubar
  window_size
)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
endforeach(plugin)
