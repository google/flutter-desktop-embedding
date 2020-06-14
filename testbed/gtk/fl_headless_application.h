#ifndef FLUTTER_FL_HEADLESS_APPLICATION_H_
#define FLUTTER_FL_HEADLESS_APPLICATION_H_

#include <gio/gio.h>

G_DECLARE_FINAL_TYPE(FlHeadlessApplication, fl_headless_application, FL,
                     HEADLESS_APPLICATION, GApplication)

/**
 * fl_headless_application_new:
 *
 * Creates a new Flutter headless application.
 *
 * Returns: a new #FlHeadlessApplication.
 */
FlHeadlessApplication* fl_headless_application_new();

#endif  // FLUTTER_FL_HEADLESS_APPLICATION_H_

