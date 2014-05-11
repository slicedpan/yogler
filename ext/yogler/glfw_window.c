#include <ruby.h>
#include <GLFW/glfw3.h>
#include "glfw_classes.h"
#include "utils.h"

VALUE create_window(VALUE self, VALUE width, VALUE height, VALUE title, VALUE monitor, VALUE share) {
  char* title_string = NULL;
  GLFWmonitor* monitor_ptr = NULL;
  GLFWwindow* share_ptr = NULL;
  GLFWwindow* window = NULL;
  VALUE new_window;
  
  title_string = create_cstring_from_rstring(title);
  
  if (monitor != Qnil) {
    Data_Get_Struct(monitor, GLFWmonitor, monitor_ptr);
  }  
  
  if (share != Qnil) {
    Data_Get_Struct(share, GLFWwindow, share_ptr);
  }
  
  window = glfwCreateWindow(FIX2INT(width), FIX2INT(height), title_string, monitor_ptr, share_ptr);
  if (!window) {
    return Qnil;
  }
  
  new_window = Data_Wrap_Struct(glfw_window_class, NULL, NULL, window);
  rb_iv_set(new_window, "@title", title);
  free(title_string);
  return new_window;
 
}

VALUE swap_buffers(VALUE self) {
  GLFWwindow* window;
  Data_Get_Struct(self, GLFWwindow, window);  
  glfwSwapBuffers(window);  
  return Qnil;
}

VALUE destroy_window(VALUE self) {
  GLFWwindow* window;
  Data_Get_Struct(self, GLFWwindow, window);
  glfwDestroyWindow(window);
  return Qnil;
}

VALUE show_window(VALUE self) {
  GLFWwindow* window;
  Data_Get_Struct(self, GLFWwindow, window);
  glfwShowWindow(window);
  return Qnil;
}

VALUE hide_window(VALUE self) {
  GLFWwindow* window;
  Data_Get_Struct(self, GLFWwindow, window);
  glfwHideWindow(window);
  return Qnil;
}

VALUE poll_events(VALUE self) {
  glfwPollEvents();
  return Qnil;
}

VALUE wait_events(VALUE self) {
  glfwWaitEvents();
  return Qnil;
}

VALUE set_title(VALUE self, VALUE title) {
  GLFWwindow* window;
  char* title_str;
  
  Data_Get_Struct(self, GLFWwindow, window);
  rb_iv_set(self, "@title", title);
  title_str = create_cstring_from_rstring(title);
  glfwSetWindowTitle(window, title_str);
  free(title_str);
  return Qnil;
}

VALUE get_title(VALUE self) {
  return rb_iv_get(self, "@title");
}

void init_glfw_window() {
  rb_define_singleton_method(glfw_window_class, "create", create_window, 5);
  rb_define_singleton_method(glfw_window_class, "poll_events", poll_events, 0);
  rb_define_method(glfw_window_class, "swap_buffers", swap_buffers, 0);
  rb_define_method(glfw_window_class, "destroy", destroy_window, 0);
  rb_define_method(glfw_window_class, "hide", hide_window, 0);
  rb_define_method(glfw_window_class, "show", show_window, 0);
  rb_define_method(glfw_window_class, "title", get_title, 0);
  rb_define_method(glfw_window_class, "title=", set_title, 1);
}


