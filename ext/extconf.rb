# ext/extconf.rb

require 'fileutils'
require 'rbconfig'

# Set root_dir to the project root directory
root_dir = File.expand_path('..', __dir__)

# Define the whisper.cpp directory path
whisper_dir = File.join(__dir__, 'whisper.cpp')

puts "Root Directory: #{root_dir}"
puts "Whisper.cpp Directory: #{whisper_dir}"

# Clone or update the whisper.cpp repository
if Dir.exist?(whisper_dir)
  # If the directory exists, check if it's a git repository
  Dir.chdir(whisper_dir) do
    if system('git rev-parse --is-inside-work-tree > /dev/null 2>&1')
      puts "Updating existing whisper.cpp repository..."
      # Pull the latest changes
      system 'git pull' or abort "Failed to update whisper.cpp repository"
    else
      # If it's not a git repository, remove it and clone again
      puts "Removing non-git directory #{whisper_dir}"
      FileUtils.rm_rf(whisper_dir)
      puts "Cloning whisper.cpp repository..."
      Dir.chdir(__dir__) do
        system 'git clone https://github.com/ggerganov/whisper.cpp.git' or abort "Failed to clone whisper.cpp repository"
      end
    end
  end
else
  # Clone the repository
  puts "Cloning whisper.cpp repository..."
  Dir.chdir(__dir__) do
    system 'git clone https://github.com/ggerganov/whisper.cpp.git' or abort "Failed to clone whisper.cpp repository"
  end
end

# Verify that the whisper.cpp directory now exists
unless Dir.exist?(whisper_dir)
  abort "Failed to find or create the whisper.cpp directory at #{whisper_dir}"
end

# Now, proceed to build libwhispercpp.so using the whisper.cpp Makefile
Dir.chdir(whisper_dir) do
  # Set environment variables for build settings
  ENV['GGML_CUDA'] = '1'  # Enable CUDA support

  puts "Building libwhispercpp.so with GGML_CUDA=#{ENV['GGML_CUDA']}..."

  # Build libwhisper.a and libggml.a
  unless system 'make clean && make -j libwhisper.a libggml.a'
    abort "Failed to build libwhisper.a and libggml.a"
  end

  # Link the static libraries into a single shared library using g++
  gcc_command = 'g++ -shared -o libwhispercpp.so ' \
                '-Wl,--whole-archive libwhisper.a -Wl,--no-whole-archive libggml.a ' \
                '-L$( [ -d /opt/cuda ] && echo /opt/cuda/lib || echo /usr/local/cuda/lib ) ' \
                '-lcuda -lcudart -lcublas -lc -lm -lstdc++'

  unless system gcc_command
    abort "Failed to link libwhispercpp.so"
  end

  # Verify that libwhispercpp.so was created
  source_lib = File.join(Dir.pwd, 'libwhispercpp.so')
  unless File.exist?(source_lib)
    abort "libwhispercpp.so not found after compilation"
  end

  # Copy the compiled library to the gem's lib directory
  FileUtils.cp(source_lib, root_dir)

  puts "Copied libwhispercpp.so to #{root_dir}"
end

puts "Compilation completed."

# Create a no-op Makefile to prevent RubyGems from attempting further compilation
makefile_content = <<~MAKEFILE
  all:
  	@echo 'libwhispercpp.so already built.'
  install:
  	@echo 'libwhispercpp.so already installed.'
MAKEFILE

File.open('Makefile', 'w') do |f|
  f.write(makefile_content)
end

puts "Created a no-op Makefile to prevent further compilation."

# After copying libwhispercpp.so

# Path to the cloned whisper.cpp directory
cloned_dir = whisper_dir

# Remove the cloned whisper.cpp directory
puts "Removing cloned whisper.cpp directory at #{cloned_dir}..."
FileUtils.rm_rf(cloned_dir)

puts "Removed cloned whisper.cpp directory."


