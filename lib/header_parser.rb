require 'ffi'
require 'strscan'

module Yogler
  module HeaderParser
    def self.parse_header(filename, module_name)
      ss = StringScanner.new(File.open(filename).read)
    end
    def self.create_module(module_name, lib_name, c_functions)
      function_string = ""
      c_functions.each do |c_f|
        function_string << "attach_function "
        function_string << ":#{c_f[0]}, ["
        function_string << c_f[1].map{|arg| ":#{arg}"}.join(", ")
        function_string << "], :#{c_f[2]}\n"
      end
      Yogler.class_eval "
        module #{module_name}
          extend FFI::Library
          ffi_lib '#{lib_name}'
          #{function_string}
        end
      "
    end    
  end
end
