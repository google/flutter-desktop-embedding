#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(FlApplication, fl_application, FL, APPLICATION,
                     GtkApplication)

FlApplication* fl_application_new();
