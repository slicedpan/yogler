module Yogler
  module GL  
    include LibLoader
    load_lib :gl
  end
  
  module GLEW
    include LibLoader
    load_lib :glew
  end
  
end
