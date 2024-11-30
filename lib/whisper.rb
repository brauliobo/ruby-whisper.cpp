require 'ffi'

module Whisper
  extend FFI::Library

  # Load the shared library
  lib_path = File.expand_path '../../libwhispercpp.so', __FILE__
  ffi_lib lib_path

  # Enums and Constants
  WHISPER_SAMPLING_GREEDY = 0
  WHISPER_SAMPLING_BEAM_SEARCH = 1

  # Enums for alignment heads preset
  enum :whisper_alignment_heads_preset, [
    :WHISPER_AHEADS_NONE,
    :WHISPER_AHEADS_N_TOP_MOST,
    :WHISPER_AHEADS_CUSTOM,
    :WHISPER_AHEADS_TINY_EN,
    :WHISPER_AHEADS_TINY,
    :WHISPER_AHEADS_BASE_EN,
    :WHISPER_AHEADS_BASE,
    :WHISPER_AHEADS_SMALL_EN,
    :WHISPER_AHEADS_SMALL,
    :WHISPER_AHEADS_MEDIUM_EN,
    :WHISPER_AHEADS_MEDIUM,
    :WHISPER_AHEADS_LARGE_V1,
    :WHISPER_AHEADS_LARGE_V2,
    :WHISPER_AHEADS_LARGE_V3,
    :WHISPER_AHEADS_LARGE_V3_TURBO  # Added new enum value
  ]

  # Enums for grammar element type
  enum :whisper_gretype, [
    :WHISPER_GRETYPE_END,            0,
    :WHISPER_GRETYPE_ALT,
    :WHISPER_GRETYPE_RULE_REF,
    :WHISPER_GRETYPE_CHAR,
    :WHISPER_GRETYPE_CHAR_NOT,
    :WHISPER_GRETYPE_CHAR_RNG_UPPER,
    :WHISPER_GRETYPE_CHAR_ALT
  ]

  # Enums for sampling strategy
  enum :whisper_sampling_strategy, [
    :WHISPER_SAMPLING_GREEDY,
    :WHISPER_SAMPLING_BEAM_SEARCH
  ]

  # Callbacks
  callback :whisper_new_segment_callback, [:pointer, :pointer, :int, :pointer], :void
  callback :whisper_progress_callback, [:pointer, :pointer, :int, :pointer], :void
  callback :whisper_encoder_begin_callback, [:pointer, :pointer, :pointer], :bool
  callback :whisper_logits_filter_callback, [:pointer, :pointer, :pointer, :int, :pointer, :pointer], :void
  callback :ggml_abort_callback, [:pointer], :bool
  callback :ggml_log_callback, [:int, :string, :pointer], :void

  # Structs Definitions

  # whisper_ahead struct
  class WhisperAhead < FFI::Struct
    layout(
      :n_text_layer, :int,
      :n_head, :int
    )
  end

  # whisper_aheads struct
  class WhisperAheads < FFI::Struct
    layout(
      :n_heads, :size_t,
      :heads, :pointer # Pointer to array of WhisperAhead
    )
  end

  # whisper_context_params struct
  class WhisperContextParams < FFI::Struct
    layout(
      :use_gpu, :bool,
      :flash_attn, :bool,
      :gpu_device, :int,
      :dtw_token_timestamps, :bool,
      :dtw_aheads_preset, :whisper_alignment_heads_preset,
      :dtw_n_top, :int,
      :dtw_aheads, WhisperAheads,
      :dtw_mem_size, :size_t
    )
  end

  # whisper_token_data struct
  class WhisperTokenData < FFI::Struct
    layout(
      :id, :int32,
      :tid, :int32,
      :p, :float,
      :plog, :float,
      :pt, :float,
      :ptsum, :float,
      :t0, :int64,
      :t1, :int64,
      :t_dtw, :int64,
      :vlen, :float
    )
  end

  # whisper_model_loader struct
  #class WhisperModelLoader < FFI::Struct
  #  callback :read_callback, [:pointer, :pointer], :size_t
  #  callback :eof_callback, [:pointer], :bool
  #  callback :close_callback, [:pointer], :void

  #  layout(
  #    :context, :pointer,
  #    :read, :read_callback,
  #    :eof, :eof_callback,
  #    :close, :close_callback
  #  )
  #end

  # whisper_grammar_element struct
  class WhisperGrammarElement < FFI::Struct
    layout(
      :type, :whisper_gretype,
      :value, :uint32
    )
  end

  # greedy sampling parameters
  class WhisperGreedyParams < FFI::Struct
    layout(
      :best_of, :int
    )
  end

  # beam search sampling parameters
  class WhisperBeamSearchParams < FFI::Struct
    layout(
      :beam_size, :int,
      :patience, :float
    )
  end

  # whisper_full_params struct
  class WhisperFullParams < FFI::Struct
    layout(
      :strategy, :whisper_sampling_strategy,
      :n_threads, :int,
      :n_max_text_ctx, :int,
      :offset_ms, :int,
      :duration_ms, :int,
      :translate, :bool,
      :no_context, :bool,
      :no_timestamps, :bool,
      :single_segment, :bool,
      :print_special, :bool,
      :print_progress, :bool,
      :print_realtime, :bool,
      :print_timestamps, :bool,
      :token_timestamps, :bool,
      :thold_pt, :float,
      :thold_ptsum, :float,
      :max_len, :int,
      :split_on_word, :bool,
      :max_tokens, :int,
      :debug_mode, :bool,
      :audio_ctx, :int,
      :tdrz_enable, :bool,
      :suppress_regex, :pointer,
      :initial_prompt, :pointer,
      :prompt_tokens, :pointer,
      :prompt_n_tokens, :int,
      :language, :pointer,
      :detect_language, :bool,
      :suppress_blank, :bool,
      :suppress_non_speech_tokens, :bool,
      :temperature, :float,
      :max_initial_ts, :float,
      :length_penalty, :float,
      :temperature_inc, :float,
      :entropy_thold, :float,
      :logprob_thold, :float,
      :no_speech_thold, :float,
      :greedy, WhisperGreedyParams,
      :beam_search, WhisperBeamSearchParams,
      :new_segment_callback, :whisper_new_segment_callback,
      :new_segment_callback_user_data, :pointer,
      :progress_callback, :whisper_progress_callback,
      :progress_callback_user_data, :pointer,
      :encoder_begin_callback, :whisper_encoder_begin_callback,
      :encoder_begin_callback_user_data, :pointer,
      :abort_callback, :ggml_abort_callback,
      :abort_callback_user_data, :pointer,
      :logits_filter_callback, :whisper_logits_filter_callback,
      :logits_filter_callback_user_data, :pointer,
      :grammar_rules, :pointer,
      :n_grammar_rules, :size_t,
      :i_start_rule, :size_t,
      :grammar_penalty, :float
    )
  end

  # Get default context params
  attach_function :whisper_context_default_params, [], WhisperContextParams.by_value
  attach_function :whisper_context_default_params_by_ref, [], :pointer
  # Get default full params
  attach_function :whisper_full_default_params, [:whisper_sampling_strategy], WhisperFullParams.by_value
  attach_function :whisper_full_default_params_by_ref, [:whisper_sampling_strategy], :pointer

  # Function Bindings

  # Initialize context with params
  attach_function :whisper_init_from_file_with_params, [:string, WhisperContextParams.by_value], :pointer
  attach_function :whisper_init_from_buffer_with_params, [:pointer, :size_t, WhisperContextParams.by_value], :pointer
  #attach_function :whisper_init_with_params, [WhisperModelLoader.by_ref, WhisperContextParams.by_value], :pointer

  # Initialize context without state
  attach_function :whisper_init_from_file_with_params_no_state, [:string, WhisperContextParams.by_value], :pointer
  attach_function :whisper_init_from_buffer_with_params_no_state, [:pointer, :size_t, WhisperContextParams.by_value], :pointer
  #attach_function :whisper_init_with_params_no_state, [WhisperModelLoader.by_ref, WhisperContextParams.by_value], :pointer

  # Initialize state
  attach_function :whisper_init_state, [:pointer], :pointer

  # OpenVINO functions
  attach_function :whisper_ctx_init_openvino_encoder_with_state, [:pointer, :pointer, :string, :string, :string], :int
  attach_function :whisper_ctx_init_openvino_encoder, [:pointer, :string, :string, :string], :int

  # Free functions
  attach_function :whisper_free, [:pointer], :void
  attach_function :whisper_free_state, [:pointer], :void
  attach_function :whisper_free_params, [:pointer], :void
  attach_function :whisper_free_context_params, [:pointer], :void

  # PCM to Mel spectrogram
  attach_function :whisper_pcm_to_mel, [:pointer, :pointer, :int, :int], :int
  attach_function :whisper_pcm_to_mel_with_state, [:pointer, :pointer, :pointer, :int, :int], :int

  # Set custom Mel spectrogram
  attach_function :whisper_set_mel, [:pointer, :pointer, :int, :int], :int
  attach_function :whisper_set_mel_with_state, [:pointer, :pointer, :pointer, :int, :int], :int

  # Encode
  attach_function :whisper_encode, [:pointer, :int, :int], :int
  attach_function :whisper_encode_with_state, [:pointer, :pointer, :int, :int], :int

  # Decode
  attach_function :whisper_decode, [:pointer, :pointer, :int, :int, :int], :int
  attach_function :whisper_decode_with_state, [:pointer, :pointer, :pointer, :int, :int, :int], :int

  # Tokenize
  attach_function :whisper_tokenize, [:pointer, :string, :pointer, :int], :int
  attach_function :whisper_token_count, [:pointer, :string], :int

  # Language functions
  attach_function :whisper_lang_max_id, [], :int
  attach_function :whisper_lang_id, [:string], :int
  attach_function :whisper_lang_str, [:int], :string
  attach_function :whisper_lang_str_full, [:int], :string

  # Auto-detect language
  attach_function :whisper_lang_auto_detect, [:pointer, :int, :int, :pointer], :int
  attach_function :whisper_lang_auto_detect_with_state, [:pointer, :pointer, :int, :int, :pointer], :int

  # Model info
  attach_function :whisper_n_len, [:pointer], :int
  attach_function :whisper_n_len_from_state, [:pointer], :int
  attach_function :whisper_n_vocab, [:pointer], :int
  attach_function :whisper_n_text_ctx, [:pointer], :int
  attach_function :whisper_n_audio_ctx, [:pointer], :int
  attach_function :whisper_is_multilingual, [:pointer], :int

  attach_function :whisper_model_n_vocab, [:pointer], :int
  attach_function :whisper_model_n_audio_ctx, [:pointer], :int
  attach_function :whisper_model_n_audio_state, [:pointer], :int
  attach_function :whisper_model_n_audio_head, [:pointer], :int
  attach_function :whisper_model_n_audio_layer, [:pointer], :int
  attach_function :whisper_model_n_text_ctx, [:pointer], :int
  attach_function :whisper_model_n_text_state, [:pointer], :int
  attach_function :whisper_model_n_text_head, [:pointer], :int
  attach_function :whisper_model_n_text_layer, [:pointer], :int
  attach_function :whisper_model_n_mels, [:pointer], :int
  attach_function :whisper_model_ftype, [:pointer], :int
  attach_function :whisper_model_type, [:pointer], :int

  # Get logits
  attach_function :whisper_get_logits, [:pointer], :pointer
  attach_function :whisper_get_logits_from_state, [:pointer], :pointer

  # Token functions
  attach_function :whisper_token_to_str, [:pointer, :int32], :string
  attach_function :whisper_model_type_readable, [:pointer], :string

  # Special tokens
  attach_function :whisper_token_eot, [:pointer], :int32
  attach_function :whisper_token_sot, [:pointer], :int32
  attach_function :whisper_token_solm, [:pointer], :int32
  attach_function :whisper_token_prev, [:pointer], :int32
  attach_function :whisper_token_nosp, [:pointer], :int32
  attach_function :whisper_token_not, [:pointer], :int32
  attach_function :whisper_token_beg, [:pointer], :int32
  attach_function :whisper_token_lang, [:pointer, :int], :int32

  # Task tokens
  attach_function :whisper_token_translate, [:pointer], :int32
  attach_function :whisper_token_transcribe, [:pointer], :int32

  # Timings
  attach_function :whisper_print_timings, [:pointer], :void
  attach_function :whisper_reset_timings, [:pointer], :void
  attach_function :whisper_print_system_info, [], :string

  # Full transcription function
  attach_function :whisper_full, [:pointer, WhisperFullParams.by_value, :pointer, :int], :int
  attach_function :whisper_full_with_state, [:pointer, :pointer, WhisperFullParams.by_value, :pointer, :int], :int

  # Parallel processing
  attach_function :whisper_full_parallel, [:pointer, WhisperFullParams.by_value, :pointer, :int, :int], :int

  # Number of segments
  attach_function :whisper_full_n_segments, [:pointer], :int
  attach_function :whisper_full_n_segments_from_state, [:pointer], :int

  # Get segment info
  attach_function :whisper_full_get_segment_t0, [:pointer, :int], :int64
  attach_function :whisper_full_get_segment_t0_from_state, [:pointer, :int], :int64

  attach_function :whisper_full_get_segment_t1, [:pointer, :int], :int64
  attach_function :whisper_full_get_segment_t1_from_state, [:pointer, :int], :int64

  attach_function :whisper_full_get_segment_speaker_turn_next, [:pointer, :int], :bool
  attach_function :whisper_full_get_segment_speaker_turn_next_from_state, [:pointer, :int], :bool

  attach_function :whisper_full_get_segment_text, [:pointer, :int], :string
  attach_function :whisper_full_get_segment_text_from_state, [:pointer, :int], :string

  attach_function :whisper_full_n_tokens, [:pointer, :int], :int
  attach_function :whisper_full_n_tokens_from_state, [:pointer, :int], :int

  attach_function :whisper_full_get_token_text, [:pointer, :int, :int], :string
  attach_function :whisper_full_get_token_text_from_state, [:pointer, :pointer, :int, :int], :string

  attach_function :whisper_full_get_token_id, [:pointer, :int, :int], :int32
  attach_function :whisper_full_get_token_id_from_state, [:pointer, :int, :int], :int32

  attach_function :whisper_full_get_token_data, [:pointer, :int, :int], WhisperTokenData.by_value
  attach_function :whisper_full_get_token_data_from_state, [:pointer, :int, :int], WhisperTokenData.by_value

  attach_function :whisper_full_get_token_p, [:pointer, :int, :int], :float
  attach_function :whisper_full_get_token_p_from_state, [:pointer, :int, :int], :float

  # Language ID
  attach_function :whisper_full_lang_id, [:pointer], :int
  attach_function :whisper_full_lang_id_from_state, [:pointer], :int

  # Benchmarks
  attach_function :whisper_bench_memcpy, [:int], :int
  attach_function :whisper_bench_memcpy_str, [:int], :string
  attach_function :whisper_bench_ggml_mul_mat, [:int], :int
  attach_function :whisper_bench_ggml_mul_mat_str, [:int], :string

  # Set the log callback
  attach_function :whisper_log_set, [:ggml_log_callback, :pointer], :void

  # Define a no-op log callback to suppress debug messages
  NOOP_LOG_CALLBACK = FFI::Function.new(:void, [:int, :string, :pointer]) do |level, msg, user_data|
    # Intentionally do nothing to suppress logs
  end
  # Set the no-op log callback to suppress logging
  Whisper.whisper_log_set NOOP_LOG_CALLBACK, FFI::Pointer::NULL unless ENV['WHISPER_DEBUG']
end

