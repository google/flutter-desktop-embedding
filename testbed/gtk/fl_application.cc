#include "fl_application.h"

#include <flutter_linux/flutter_linux.h>

#include "flutter/gtk_plugin_registrant.h"
#include "window_configuration.h"

struct _FlApplication {
  GtkApplication parent_instance;
};

G_DEFINE_TYPE(FlApplication, fl_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void fl_application_activate(GApplication* application) {
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  gtk_widget_show(GTK_WIDGET(window));
  gtk_widget_set_size_request(GTK_WIDGET(window), kFlutterWindowWidth,
                              kFlutterWindowHeight);
  gtk_window_set_title(window, kFlutterWindowTitle);

  g_autoptr(FlDartProject) project = fl_dart_project_new();

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static void fl_application_class_init(FlApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = fl_application_activate;
}

static void fl_application_init(FlApplication* self) {}

FlApplication* fl_application_new() {
  return FL_APPLICATION(g_object_new(fl_application_get_type(), nullptr));
}
