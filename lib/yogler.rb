$:.push File.dirname(__FILE__)
require 'header_parser'
require 'lib_loader'

module Yogler

  include LibLoader
  
  #load_lib :glfw
  #load_lib :glew

  class Engine
    def run
      @window = GLFW.create_window(640, 480, "Hello world", nil, nil)
      GLFW.make_context_current(@window)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  $:.push(File.dirname(__FILE__) + '../')
  engine = Yogler::Engine.new
  engine.run
end
