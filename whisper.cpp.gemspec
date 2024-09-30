require_relative 'lib/whisper/version'

Gem::Specification.new do |spec|
  spec.name          = 'whisper.cpp'
  spec.version       = Whisper::VERSION
  spec.authors       = ['Braulio Oliveira']
  spec.email         = ['brauliobo@gmail.com']

  spec.summary       = 'Ruby bindings for whisper.cpp'
  spec.description   = 'A Ruby gem that provides bindings to the whisper.cpp library for speech transcription.'
  # spec.homepage      = 'http://example.com/whisper.cpp'
  spec.license       = 'MIT'

  # Use git ls-files to specify files to include in the gem
  spec.files = `git ls-files -z`.split("\x0")

  # Specify the extension to build
  spec.extensions = ['ext/extconf.rb']

  # Dependencies
  spec.add_dependency 'ffi', '~> 1.15'

  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'pry'
end

