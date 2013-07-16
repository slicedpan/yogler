require 'yaml'
require 'ffi'

module Yogler
  module LibLoader
  
    TESTING = true
    
    def self.debug(arg)
      puts arg if TESTING
    end
  
    def self.libs
      @libs || {}
    end
    
  
    def self.create_lib(lib_name)
      opts = libs[lib_name.to_s]

      opts["function_list"] = File.open("data/libs/" + opts["function_list_filename"]).each_line.to_a.map { |l| l.rstrip.lstrip }
      if !opts["header_filename"].match(/[\/\\]/) # ]/ # ruby syntax highlight error in gedit
        opts["header_filename"] = "data/libs/#{opts['header_filename']}"
      end
      
      debug opts
      
      function_string = ""
      
      header_parser = HeaderParser.new(opts)
      header_parser.parse
      header_parser.functions.each do |c_f|
        debug "adding function: #{c_f[:r_name]}"
        function_string << "attach_function :#{c_f[:r_name]}, "
        function_string << ":#{c_f[:c_name]}, ["
        function_string << c_f[:c_args].map{|arg| ":#{arg}"}.join(", ")
        function_string << "], :#{c_f[:c_ret_type]}\n"
      end
      
      if !@base_module.included_modules.include? FFI::Library
        @base_module.extend FFI::Library
      end
      str = "
          ffi_lib '#{opts['lib_name']}'
          #{function_string}
      "
      
      debug str

      @base_module.class_eval str
      
    end       
      
    def self.included(includer)
      @base_module = includer
      @libs = YAML.load_file "data/libs.yml"
      includer.send(:extend, ClassMethods)      
    end
    
    module ClassMethods
      def load_lib(lib_name)
        LibLoader.create_lib(lib_name)        
      end 
    end
    
  end
end
