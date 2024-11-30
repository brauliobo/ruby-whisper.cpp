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

# Now, proceed to modify the Makefile and build libwhispercpp.so
Dir.chdir(whisper_dir) do
  # Set environment variables for build settings
  ENV['GGML_CUDA'] = '1'  # Enable CUDA support if desired

  # Modify the Makefile to add libwhispercpp.so target
  makefile_path = File.join(Dir.pwd, 'Makefile')

  makefile_content = File.read(makefile_path)

  # Check if 'libwhispercpp.so' target is already defined
  unless makefile_content.include?('libwhispercpp.so:')
    # Append the new target at the end of the Makefile
    new_content = <<~MAKEFILE

      # Custom target for building libwhispercpp.so
      libwhispercpp.so: $(OBJ_GGML) $(OBJ_WHISPER) $(OBJ_COMMON) $(OBJ_SDL) $(OBJ_WHISPER_EXTRA)
      \t$(CXX) $(CXXFLAGS) -shared -fPIC -o $@ $^ $(LDFLAGS)

      BUILD_TARGETS += libwhispercpp.so
    MAKEFILE

    makefile_content << new_content

    # Write back the modified Makefile
    File.open(makefile_path, 'w') do |f|
      f.write(makefile_content)
    end

    puts "Modified Makefile to add libwhispercpp.so target."
  else
    puts "Makefile already contains libwhispercpp.so target."
  end

  puts "Building libwhispercpp.so with GGML_CUDA=#{ENV['GGML_CUDA']}..."

  # Build libwhispercpp.so
  unless system 'make clean && make -j libwhispercpp.so'
    abort "Failed to build libwhispercpp.so"
  end

  # Verify that libwhispercpp.so was created
  source_lib = File.join(Dir.pwd, 'libwhispercpp.so')
  unless File.exist?(source_lib)
    abort "libwhispercpp.so not found after compilation"
  end

  # Copy the compiled library to the gem's root directory
  destination_lib = File.join(root_dir, 'libwhispercpp.so')
  FileUtils.cp(source_lib, destination_lib)

  puts "Copied libwhispercpp.so to #{destination_lib}"
end

puts "Compilation completed."

# Create a no-op Makefile to prevent RubyGems from attempting further compilation
makefile_content = <<~MAKEFILE
  all:
  \t@echo 'libwhispercpp.so already built.'
  install:
  \t@echo 'libwhispercpp.so already installed.'
MAKEFILE

File.open('Makefile', 'w') do |f|
  f.write(makefile_content)
end

puts "Created a no-op Makefile to prevent further compilation."

# Remove the cloned whisper.cpp directory
cloned_dir = whisper_dir

puts "Removing cloned whisper.cpp directory at #{cloned_dir}..."
FileUtils.rm_rf(cloned_dir)
puts "Removed cloned whisper.cpp directory."

