require 'ffi'

module Yogler
  module GLFW
    extend FFI::Library
    ffi_lib 'glfw'
    attach_function :glfwCreateWindow, 
      [:int, :int, :string, :pointer, :pointer],
      :pointer
    attach_function :glfwMakeContextCurrent, [:pointer], :void
    attach_function :glfwInit, [], :bool
  end 
end
