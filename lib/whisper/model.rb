require_relative '../whisper'
require_relative 'audio_processor'

module Whisper
  class Model

    TranscriptionResult = Struct.new :language, :output

    def initialize model_path
      params = Whisper.whisper_context_default_params
      # Modify params as needed
      params[:use_gpu] = true
      params[:gpu_device] = 0

      @ctx = Whisper.whisper_init_from_file_with_params model_path, params
      raise 'Failed to initialize Whisper model' if @ctx.null?
    end

    def transcribe_from_file(audio_file_path, format: 'plaintext')
      # Load audio file and convert to float array
      audio_data = Whisper::AudioProcessor.convert_to_float_array audio_file_path

      # Prepare full params
      params = Whisper.whisper_full_default_params Whisper::WHISPER_SAMPLING_GREEDY
      params[:n_threads] = 4
      params[:translate] = false
      params[:language] = FFI::Pointer::NULL # Auto-detect language

      # Prepare audio data pointer
      n_samples = audio_data.size
      samples_ptr = FFI::MemoryPointer.new(:float, n_samples)
      samples_ptr.write_array_of_float audio_data

      # Call the whisper_full function
      result = Whisper.whisper_full @ctx, params, samples_ptr, n_samples
      raise 'Transcription failed' if result != 0

      # Retrieve detected language
      lang_id = Whisper.whisper_full_lang_id(@ctx)
      language = Whisper.whisper_lang_str(lang_id)

      n_segments = Whisper.whisper_full_n_segments @ctx
      output = ''
      case format.downcase
      when 'plaintext'
        n_segments.times do |i|
          segment_text = Whisper.whisper_full_get_segment_text @ctx, i
          output += segment_text
        end
      when 'srt'
        n_segments.times do |i|
          start_time   = Whisper.whisper_full_get_segment_t0(@ctx, i) / 100.0
          end_time     = Whisper.whisper_full_get_segment_t1(@ctx, i) / 100.0
          segment_text = Whisper.whisper_full_get_segment_text @ctx, i

          output += "#{i + 1}\n"
          output += "#{format_time_srt start_time} --> #{format_time_srt end_time}\n"
          output += "#{segment_text.strip}\n\n"
        end
      else
        raise "Unsupported format: #{format}"
      end

      TranscriptionResult.new language, output
    end

    def close
      Whisper.whisper_free @ctx
    end

    private

    def format_time_srt seconds
      hours   = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      secs    = (seconds % 60).to_i
      millis  = ((seconds - seconds.to_i) * 1000).to_i
      format '%02d:%02d:%02d,%03d', hours, minutes, secs, millis
    end

  end
end

