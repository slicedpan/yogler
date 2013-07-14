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
    
    attr_accessor :typedefs, :type_conv, :callbacks
  
    def initialize(opts) 
      @typedefs = []     
      File.open(opts['header_filename']) do |file|
        @header_lines = file.each_line.to_a.map do |l| 
          l.gsub!("extern", "")
          l.gsub!(/__attribute__ \(.*\) /, "")
          l.rstrip.lstrip
          if l.match "typedef"          
            @typedefs.push l
          end
          l
        end
      end
      
      @type_conv = {}
      @callbacks = []
      
      @module_name = opts['module_name']
      @function_names = opts['function_list']
      @ffi_functions = []
      @prefix = opts['prefix']
    end
    
    def check_callback(type)
      i = @typedefs.find_index { |l| l.match(Regexp.new("( * #{type})")) }
      if i.nil?
        puts "callback <#{type}> not found"
      else
        ret_type = ""
        puts @typedefs[i]
        line_text = @typedefs[i].dup
        line_text.gsub!("typedef ", "")
        ret_type = line_text.match(/([^\(]*)\( \* /)[1]
        puts ret_type
        ffi_type ret_type
      end
    end
    
    def try_resolve_type(c_type)
      return @type_conv[c_type] if @type_conv.keys.include? c_type
      i = @typedefs.find_index { |l| l.match(Regexp.new("#{c_type};$")) }
      
      check_callback(c_type)
      
      if i.nil?
        puts "no match found for #{c_type}"
        nil
      else
        puts "#{@header_lines[i]} has a typedef for #{c_type}"
        tokens = @header_lines[i].split(" ")
        tokens.pop
        tokens.shift
        ret_type = ffi_type(tokens)
        if ret_type.nil?
          puts "could not resolve type"
        else
          puts "resolved to #{ret_type}"
          @type_conv[c_type] = ret_type
        end
        ret_type
      end      
    end

    def ffi_type(c_type)
      c_type = c_type[0] if c_type.class == Array && c_type.length == 1
      puts "testing #{c_type}"
      if c_type.class.to_s == "String"
        if c_type =~ PTR_REGEX
          "pointer"
        elsif TYPE_SAME.include? c_type
          c_type
        end
      elsif c_type.class.to_s == "Array"        
        type_name = ffi_type c_type.pop
        puts "base type: #{type_name}"
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
      @function_names.each do |f_n|
        @header_lines.each do |t| 
          if t.match f_n
          
            puts "matched #{t}"
          
            ret_c_type = t.split(f_n)[0].lstrip.rstrip
            ret_type = ffi_type(ret_c_type) || try_resolve_type(ret_c_type)
            next if ret_type.nil?
            #puts "orig: <#{ret_c_type}>, ffi: <#{ret_type}>"
            ffi_args = []
            
            should_continue = true
            c_args = t.split(f_n)[1].match(/\((.*)\)/)[1].split(",").map {|a| a.rstrip.lstrip}
            
            unless c_args[0] == "void" && c_args.length == 1
              c_args.each do |c_a|
                tokens = c_a.split(" ")
                break if tokens.nil?                
                tokens.pop
                arg_ffi_type = ffi_type(tokens) || try_resolve_type(tokens)
                if arg_ffi_type.nil?
                  should_continue = false
                  break
                end
                ffi_args.push arg_ffi_type
              end
            end
            
            r_name = f_n.dup
            
            puts "prefix: #{@prefix}"
            
            if !@prefix.nil?
              puts "r_name before: #{r_name}"
              r_name.gsub!(@prefix, "")
              puts "r_name after: #{r_name}"
            end
            
            r_name = r_name.snake_case
            
            next unless should_continue
            
            puts "adding function #{f_n}"            
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
