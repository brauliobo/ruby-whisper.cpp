require_relative '../whisper'
require_relative 'audio_processor'

module Whisper
  class Model
    TranscriptionResult = Struct.new(:language, :output)

    def initialize(model_path)
      @model_path = model_path
      @ctx = nil
      @state = nil
      init_whisper_context
      init_whisper_state
    end

    def transcribe_from_file(audio_file_path, format: 'plaintext', **params)
      # Load audio file and convert to float array
      audio_data = Whisper::AudioProcessor.convert_to_float_array audio_file_path
      transcribe_from_audio_data audio_data, format: format, **params
    end

    def transcribe_from_audio_data(audio_data, format: 'plaintext', **params)
      # Prepare full params
      full_params = default_full_params params

      # Prepare audio data pointer
      n_samples = audio_data.size
      samples_ptr = FFI::MemoryPointer.new :float, n_samples
      samples_ptr.write_array_of_float audio_data

      # Call the whisper_full_with_state function
      result = Whisper.whisper_full_with_state @ctx, @state, full_params, samples_ptr, n_samples
      raise 'Transcription failed' if result != 0

      # Retrieve detected language
      lang_id = Whisper.whisper_full_lang_id_from_state @state
      language = Whisper.whisper_lang_str lang_id

      # Retrieve the transcription output
      n_segments = Whisper.whisper_full_n_segments_from_state @state
      output = format_transcription format, n_segments: n_segments

      TranscriptionResult.new language, output
    end

    def close
      Whisper.whisper_free_state @state unless @state.nil?
      Whisper.whisper_free @ctx unless @ctx.nil?
    end

    private

    def init_whisper_context params = {}
      return unless @ctx.nil?

      ctx_params = Whisper.whisper_context_default_params

      params.select{ |k, _| ctx_params.members.include? k }.each do |key, value|
        ctx_params[key] = value
      end
      ctx_params[:gpu_device] = ENV['WHISPER_GPU']&.to_i || 0

      # Initialize context
      @ctx = Whisper.whisper_init_from_file_with_params @model_path, ctx_params
      raise 'Failed to initialize Whisper model' if @ctx.null?
    end

    def init_whisper_state
      @state = Whisper.whisper_init_state @ctx
      raise 'Failed to initialize Whisper state' if @state.null?
    end

    def default_full_params params = {}
      # Get default full params
      strategy = params.fetch :sampling_strategy, Whisper::WHISPER_SAMPLING_GREEDY
      full_params = Whisper.whisper_full_default_params strategy

      # Set translate to false to prevent translation to English
      full_params[:translate] = false
      full_params[:language] = FFI::MemoryPointer.from_string 'auto'

      # Set user-provided full params
      params.select{ |k, _| full_params.members.include? k }.each do |key, value|
        full_params[key] = value
      end

      full_params
    end

    def format_transcription(format, n_segments:)
      output = ''
      case format.downcase
      when 'plaintext'
        n_segments.times do |i|
          segment_text = Whisper.whisper_full_get_segment_text_from_state @state, i
          output += segment_text
        end
      when 'srt'
        n_segments.times do |i|
          start_time = Whisper.whisper_full_get_segment_t0_from_state(@state, i) / 100.0
          end_time = Whisper.whisper_full_get_segment_t1_from_state(@state, i) / 100.0
          segment_text = Whisper.whisper_full_get_segment_text_from_state @state, i

          output += "#{i + 1}\n"
          output += "#{format_time_srt start_time} --> #{format_time_srt end_time}\n"
          output += "#{segment_text.strip}\n\n"
        end
      else
        raise "Unsupported format: #{format}"
      end
      output
    end

    def format_time_srt(seconds)
      hours = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      secs = (seconds % 60).to_i
      millis = ((seconds - seconds.to_i) * 1000).to_i
      format '%02d:%02d:%02d,%03d', hours, minutes, secs, millis
    end
  end
end

