#include <ruby.h>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include "glfw_classes.h"
#include "yogler.h"

VALUE yogler_module;
VALUE glfw_module;

VALUE create_window(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);

void Init_yogler() {
  glfwInit();
  yogler_module = rb_define_module("Yogler");
  create_glfw_classes();    
  glewInit();
}


