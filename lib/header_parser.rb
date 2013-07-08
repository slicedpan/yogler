require 'ffi'
require 'strscan'

module Yogler


  TYPE_SPEC = {"unsigned" => "u"}
  TYPE_SAME = ["short", "int", "char", "void", "float", "double"]
  PTR_REGEX = /^.*\*$/

  module HeaderParser
<<<<<<< HEAD
    def self.parse_header(filename, module_name, function_names)
=======
    def self.ffi_type(c_type)
      puts c_type.inspect
      c_type = c_type[0] if c_type.class == Array && c_type.length == 1
      if c_type.class == String
        if c_type =~ PTR_REGEX
          "pointer"
        elsif TYPE_SAME.include? c_type
          c_type
        end
      else
        type_name = ffi_type c_type.pop
        return type_name if type_name == "pointer"
        if c_type.include? "unsigned"
          "u#{type_name}"          
        end
        #TODO cater for longs (probably not super important)
      end
    end

    def self.typedefs
      @@typedefs ||= []
    end

    def self.parse_line(line)
      tokens = line.split(" ")
      (tokens.length - 1).times do |i|
        if tokens[i] == "*"
          tokens[i - 1] = "#{tokens[i]}*"
        end
      end
      tokens.delete_if {|tok| tok == "*"}
      if tokens[0] == "typedef" 
        tokens.shift
        new_name = tokens.pop
        orig_type = ffi_type(tokens)
        typedefs.push({:type_name => new_name, :ffi_type => orig_type})
      elsif tokens[0] == "#"
        return            
      end
    end

    def self.parse_header(filename, module_name)
      File.open(filename) do |file|
        file.each_line do |line|
          puts line unless line == ""
          parse_line line         
        end
      end
>>>>>>> b69b4db952642df65e0e4f7d34ee5697c662cc88
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
