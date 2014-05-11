require_relative '../ext/yogler/yogler.so'

module Yogler
  class Engine
    def run
      
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  $:.push(File.dirname(__FILE__) + '../')
  engine = Yogler::Engine.new
  engine.run
end
