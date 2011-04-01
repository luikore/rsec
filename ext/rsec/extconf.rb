require "mkmf"
require "fileutils"

# no make ext for other ruby versions
if RUBY_PLATFORM =~ /jruby|mac|rubinius/
  File.open "#{File.dirname(__FILE__)}/Makefile", 'w' do |f|
  end
  exit 0
end

# no make ext for windows without C compiler
make_bat = "#{File.dirname(__FILE__)}/make.bat"
nmake_bat = "#{File.dirname(__FILE__)}/nmake.bat"
begin
  system 'make -v' rescue system 'nmake /?'
  FileUtils.rm_f make_bat
  FileUtils.rm_f nmake_bat
  create_makefile 'predef'
rescue => ex
  puts "no make or nmake"
  File.open make_bat, 'w' do |f|
  end
  File.open nmake_bat, 'w' do |f|
  end
end

