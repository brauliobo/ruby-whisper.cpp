Gem::Specification.new do |spec|
  spec.name          = 'whisper.cpp'
  spec.version       = '0.1.0'
  spec.authors       = ['Braulio Oliveira']
  spec.email         = ['brauliobo@gmail.com.com']

  spec.summary       = %q{Ruby bindings for whisper.cpp}
  spec.description   = %q{A Ruby gem that provides bindings to the whisper.cpp library for speech transcription.}
  #spec.homepage      = 'http://example.com/whisper.cpp'
  spec.license       = 'MIT'

  # Specify which files to include in the gem
  spec.files = Dir.glob("lib/**/*.rb") +
               Dir.glob("ext/extconf.rb")

  # Exclude the whisper.cpp directory
  spec.files.reject! { |f| f.match(%r{\Aext/whisper_cpp/whisper\.cpp/}) }

  # If you have other directories or files to exclude, add them here
  # spec.files.reject! { |f| f.match(%r{\Aother/directory/to/exclude/}) }

  # Specify the extension to build
  spec.extensions = ["ext/extconf.rb"]

  # Dependencies
  spec.add_dependency "ffi", "~> 1.15"
  spec.add_development_dependency "rake", "~> 13.0"
end

