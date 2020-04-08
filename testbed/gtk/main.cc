#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

int main(int argc, char** argv) {
  gtk_init(&argc, &argv);

  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_widget_show(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new("data");

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));

  gtk_main();

  return 0;
}
