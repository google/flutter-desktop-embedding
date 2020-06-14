#include "fl_application.h"
#include "fl_headless_application.h"

int main(int argc, char** argv) {
  g_autoptr(GApplication) app = nullptr;

  if (gdk_init_check(&argc, &argv))
    app = G_APPLICATION(fl_application_new());
  else
    app = G_APPLICATION(fl_headless_application_new());

  return g_application_run(app, argc, argv);
}
