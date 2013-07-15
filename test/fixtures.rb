@hp = Yogler::HeaderParser.new({'header_filename' => "data/libs/glfw3-preprocessed"})
@str = "PFNGLGETSTRINGIPROC"

def reload!
  load 'lib/yogler.rb'
  load 'test/fixtures.rb'
end
