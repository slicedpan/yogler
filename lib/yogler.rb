require_relative 'glfw_lib'

module Yogler
  class Engine
    def run
      @window = GLFW::glfwCreateWindow(640, 480, "Hello world", nil, nil)
      GLFW::glfwMakeContextCurrent(@window)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  engine = Yogler::Engine.new
  engine.run
end
