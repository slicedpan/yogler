#include <ruby.h>

extern VALUE glfw_window_class;
extern VALUE glfw_monitor_class;
extern VALUE glfw_module;

void init_glfw_window();
void init_glfw_monitor();

void create_glfw_classes();
