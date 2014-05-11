#include <ruby.h>
#include "yogler.h"
#include "glfw_classes.h"

VALUE glfw_window_class;
VALUE glfw_monitor_class;
VALUE glfw_module;

void create_glfw_classes() {

  glfw_window_class = rb_define_class_under(yogler_module, "Window", rb_cObject);
  glfw_monitor_class = rb_define_class_under(yogler_module, "Monitor", rb_cObject);
  
  init_glfw_window();
  init_glfw_monitor();
  
}
