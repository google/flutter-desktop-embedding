# Once the Flutter tooling switches to use GTK, this will be generated automatically.
# For now, plugins must be added here manually.
list(APPEND FLUTTER_PLUGIN_LIST
)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/gtk plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
endforeach(plugin)
