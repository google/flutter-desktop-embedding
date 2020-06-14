#include "fl_headless_application.h"

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_engine_extra.h>

#include "flutter/gtk_plugin_registrant.h"

struct _FlHeadlessApplication {
  GApplication parent_instance;

  FlEngine* engine;
};

G_DEFINE_TYPE(FlHeadlessApplication, fl_headless_application,
              G_TYPE_APPLICATION)

// Implements GApplication::activate.
static void fl_headless_application_activate(GApplication* application) {
  FlHeadlessApplication* self = FL_HEADLESS_APPLICATION(application);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  self->engine = fl_engine_new_headless(project);

  g_application_hold(application);

  fl_register_plugins(FL_PLUGIN_REGISTRY(self->engine));
}

// Implements GObject::dispose.
static void fl_headless_application_dispose(GObject* object) {
  FlHeadlessApplication* self = FL_HEADLESS_APPLICATION(object);

  g_clear_object(&self->engine);

  G_OBJECT_CLASS(fl_headless_application_parent_class)->dispose(object);
}

static void fl_headless_application_class_init(
    FlHeadlessApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = fl_headless_application_activate;
  G_OBJECT_CLASS(klass)->dispose = fl_headless_application_dispose;
}

static void fl_headless_application_init(FlHeadlessApplication* self) {}

FlHeadlessApplication* fl_headless_application_new() {
  return FL_HEADLESS_APPLICATION(
      g_object_new(fl_headless_application_get_type(), nullptr));
}
