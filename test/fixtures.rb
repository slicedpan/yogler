@hp = Yogler::HeaderParser.new({'header_filename' => "data/libs/gl-preprocessed"})
@str = "PFNGLGETSTRINGIPROC"

def reload!
  load 'lib/yogler.rb'
  load 'test/fixtures.rb'
end

#Yogler::GLFW.init
#window = Yogler::GLFW.create_window(640, 480, "blah", nil, nil)
#Yogler::GLFW.make_context_current window


