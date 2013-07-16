require 'ffi'
require 'strscan'

class String
  if !self.instance_methods.include? :snake_case
    def snake_case      
      return downcase if match(/\A[A-Z]+\z/)
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z])([A-Z])/, '\1_\2').
      downcase
    end
  end
end

module Yogler

  TYPE_SPEC = {"unsigned" => "u"}
  TYPE_SAME = ["short", "int", "char", "void", "float", "double", "bool", "size_t"]
  FFI_EXTRA_TYPES = ["uint8", "int8", "int16", "uint16", "int32", "uint32", "int64", "uint64"]
  PTR_REGEX = /^.*\*$/
  
  
  class HeaderParser
    
    attr_accessor :typedefs, :type_conv, :callbacks, :header_lines
    
    TESTING = false
    
    def debug(arg)
      if TESTING
        puts arg
      end
    end
  
    def initialize(opts) 
      @typedefs = []     
      File.open(opts['header_filename']) do |file|
        text = file.read
        text.gsub!(/^#.*$/, "")
        text.gsub!(/extern /, "")
        text.gsub!(/__attribute__ ?\(.*\) /, "")
        
        @header_lines = text.split(";").map do |l| 
          l.gsub!(/\s+/, " ")
          l.rstrip!
          l.lstrip!
          l.gsub!(/ \(|\( /, "(")
          l.gsub!(/ \)|\) /, ")")
          l << ";"
          if l.match "typedef"          
            @typedefs.push l
          end
          l
        end
      end
      
      @object_list = opts['object_list']

      
      @type_conv = {}
      @callbacks = {}
      
      @module_name = opts['module_name']
      @function_names = opts['function_list']
      @ffi_functions = []
      @prefix = opts['prefix']
      @objects = []
      
      
    end
    
    def check_callback(type)
      return type if @callbacks.keys.include? type
      i = @typedefs.find_index { |l| l.match(Regexp.new("\\( \\* #{type}\\)")) }
      if i.nil?
        debug "callback <#{type}> not found"
      else
        ret_type = ""
        debug @typedefs[i]
        line_text = @typedefs[i].dup
        line_text.gsub!("typedef ", "")
        ret_type = line_text.match(/([^\(]*)\( \* /)[1]
        debug ret_type
        ret_c_type = ffi_type ret_type.split(" ")
        args = line_text.match(Regexp.new("\\( \\* #{type}\\) \\(([^\\)]*)\\);"))[1].split(", ")
        c_args = []
        args.each do |arg|
          tokens = arg.split(" ")
          var_name = tokens.pop
          if var_name.include? '*'
            tokens.push('*')
          end
          c_args.push(ffi_type(tokens))
        end        
        debug "c_args: #{c_args}"
        
        @callbacks[type] = {:name => type.downcase, :args => c_args, :ret_type => ret_c_type}
        
        return type.downcase
        
      end
    end
    
    def try_resolve_type(c_type)
      return @type_conv[c_type] if @type_conv.keys.include? c_type
      re = Regexp.new("#{c_type};$")
      matching_line = nil
      debug re
      i = @typedefs.find_index do |l| 
        if l.match re
          debug "#{l} matches #{re}"
          matching_line = l
          true
        else
          false
        end
      end
      
      check_callback(c_type)
      
      if matching_line.nil?
        debug "no match found for #{c_type}"
        nil
      else
        debug "#{matching_line} has a typedef for #{c_type}"
        tokens = matching_line.split(" ")
        tokens.pop
        tokens.shift
        ret_type = ffi_type(tokens)
        if ret_type.nil?
          debug "could not resolve type"
        else
          debug "resolved to #{ret_type}"
          @type_conv[c_type] = ret_type
        end
        ret_type
      end      
    end

    def ffi_type(c_type)      
      debug "c_type orig: #{c_type}"
      if c_type.kind_of? Array and c_type.length == 1
        c_type = c_type[0]
      end
      debug "testing #{c_type}"
      if c_type.kind_of? String
        if c_type =~ PTR_REGEX
          "pointer"
        elsif TYPE_SAME.include? c_type
          c_type
        else
          debug "resolving #{c_type}"
          try_resolve_type c_type
        end
      elsif c_type.kind_of? Array       
        type_name = ffi_type c_type.pop
        debug "base type: #{type_name}"
        return type_name if type_name == "pointer"
        if c_type.include? "unsigned"
          return "u#{type_name}"          
        end
        type_name
        #TODO cater for longs (probably not super important)
      end
    end

    def parse_line(line)
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
    
    def parse
      parse_functions
      parse_objects if @object_list
    end
    
    def parse_objects
      @object_list.each do |o_n|
        @header_lines.each do |t|
          if t.match " #{o_n};"
            puts "matched #{t}"
          end
        end
      end 
    end

    def parse_functions
      @function_names.each do |f_n|
        debug "match string: ' #{f_n}'"
        @header_lines.each do |t|
 
          if t.match " #{f_n}"
          
            debug "matched #{t}"
          
            ret_c_type = t.split(f_n)[0].lstrip.rstrip
            ret_type = ffi_type(ret_c_type) || try_resolve_type(ret_c_type)
            next if ret_type.nil?
            #debug "orig: <#{ret_c_type}>, ffi: <#{ret_type}>"
            ffi_args = []
            
            should_continue = true
            c_args = t.split(f_n)[1].match(/\((.*)\)/)[1].split(",").map {|a| a.rstrip.lstrip}
            
            unless c_args[0] == "void" && c_args.length == 1
              c_args.each do |c_a|
                tokens = c_a.split(" ")
                break if tokens.nil?                
                var_name = tokens.pop
                tokens.push('*') if var_name.include? '*'
                arg_ffi_type = ffi_type(tokens) || try_resolve_type(tokens)
                if arg_ffi_type.nil?
                  should_continue = false
                  break
                end
                ffi_args.push arg_ffi_type
              end
            end
            
            r_name = f_n.dup
            
            debug "prefix: #{@prefix}"
            
            if !@prefix.nil?
              debug "r_name before: #{r_name}"
              r_name.gsub!(@prefix, "")
              debug "r_name after: #{r_name}"
            end
            
            r_name = r_name.snake_case
            
            next unless should_continue
            
            debug "adding function #{f_n}"            
            @ffi_functions.push({:r_name => r_name, :c_name => f_n, :c_args => ffi_args, :c_ret_type => ret_type}) 
            
          end
        end
      end
      
    end  
    
    def functions
      @ffi_functions
    end 
   
  end
end
