require 'mkmf'

have_library "glfw"
have_library "GLEW", "glewInit"
have_library "GL"

have_header "GL/glew.h"
have_header "GLFW/glfw3.h"

create_makefile "yogler/yogler"
