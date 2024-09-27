require 'open3'
require 'tmpdir'

module Whisper
  class AudioProcessor
    def self.convert_to_float_array(file_path)
      # Use ffmpeg to convert audio to 16-bit PCM WAV at 16kHz mono
      wav_file = "#{Dir.tmpdir}/temp_#{Time.now.to_i}_#{rand(1000)}.wav"
      cmd = [
        'ffmpeg', '-y', '-i', file_path,
        '-ar', '16000', '-ac', '1', '-f', 'wav', wav_file
      ]
      stdout_str, stderr_str, status = Open3.capture3(*cmd)
      raise "ffmpeg error: #{stderr_str}" unless status.success?

      # Read the WAV file and extract the PCM data
      data = File.binread wav_file
      # Skip the WAV header (44 bytes) and unpack the PCM data
      pcm_data = data[44..-1].unpack 's<*' # Little-endian 16-bit signed integers

      # Normalize and convert to float32
      pcm_data.map { |sample| sample / 32768.0 }
    ensure
      File.delete wav_file if File.exist? wav_file
    end
  end
end

