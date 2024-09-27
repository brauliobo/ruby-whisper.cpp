require 'fileutils'

# Set root_dir to the project root directory
root_dir = File.expand_path('../../..', __FILE__)

# Define the parent directory and whisper.cpp directory paths
ext_dir = File.expand_path('..', __dir__)
whisper_dir = File.join(ext_dir, 'whisper.cpp')

puts "Root Directory: #{root_dir}"
puts "Extension Directory: #{ext_dir}"
puts "Whisper.cpp Directory: #{whisper_dir}"

# Clone or update the whisper.cpp repository
if Dir.exist?(whisper_dir)
  # If the directory exists, check if it's a git repository
  Dir.chdir(whisper_dir) do
    if system('git rev-parse --is-inside-work-tree > /dev/null 2>&1')
      puts "Updating existing whisper.cpp repository..."
      # Pull the latest changes
      system 'git pull'
    else
      # If it's not a git repository, remove it and clone again
      puts "Removing non-git directory #{whisper_dir}"
      FileUtils.rm_rf(whisper_dir)
      puts "Cloning whisper.cpp repository..."
      Dir.chdir(ext_dir) do
        system 'git clone https://github.com/ggerganov/whisper.cpp.git'
      end
    end
  end
else
  # Clone the repository
  puts "Cloning whisper.cpp repository..."
  Dir.chdir(ext_dir) do
    system 'git clone https://github.com/ggerganov/whisper.cpp.git'
  end
end

# Verify that the whisper.cpp directory now exists
unless Dir.exist?(whisper_dir)
  abort "Failed to find or create the whisper.cpp directory at #{whisper_dir}"
end

# Now, proceed to build libwhispercpp.so using the modified Makefile
Dir.chdir(whisper_dir) do
  # Set environment variables for build settings
  ENV['GGML_CUDA']   = '1'  # Enable CUDA support

  puts "Building libwhispercpp.so with GGML_CUDA=#{ENV['GGML_CUDA']}..."

  # Build libwhispercpp.so
  unless system 'make -j libwhisper.a libggml.a'
    abort "Failed to build libwhisper.a"
  end

  system 'gcc -shared -o libwhispercpp.so \
    -Wl,--whole-archive libwhisper.a -Wl,--no-whole-archive libggml.a \
    -L$( [ -d /opt/cuda ] && echo /opt/cuda/lib || echo /usr/local/cuda/lib ) \
    -lcuda -lcudart -lcublas -lc -lm'

  # Verify that libwhispercpp.so was created
  source_lib = File.join(Dir.pwd, 'libwhispercpp.so')
  unless File.exist?(source_lib)
    abort "libwhispercpp.so not found after compilation"
  end

  # Copy the compiled library to the destination directory
  destination_path = root_dir
  puts "Copying libwhispercpp.so to #{destination_path}"
  FileUtils.cp(source_lib, destination_path)
end

puts "Compilation completed."

