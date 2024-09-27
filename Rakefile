# Rakefile

desc 'Compile the libwhisper_cpp.so library using extconf.rb'
task :compile do
  Dir.chdir('ext/whisper_cpp') do
    # Run extconf.rb to handle the build process
    ruby 'extconf.rb'
  end
end

