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
    :WHISPER_AHEADS_LARGE_V3
  ]

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
      :strategy, :int,
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
      :new_segment_callback, :pointer,
      :new_segment_callback_user_data, :pointer,
      :progress_callback, :pointer,
      :progress_callback_user_data, :pointer,
      :encoder_begin_callback, :pointer,
      :encoder_begin_callback_user_data, :pointer,
      :abort_callback, :pointer,
      :abort_callback_user_data, :pointer,
      :logits_filter_callback, :pointer,
      :logits_filter_callback_user_data, :pointer,
      :grammar_rules, :pointer,
      :n_grammar_rules, :size_t,
      :i_start_rule, :size_t,
      :grammar_penalty, :float
    )
  end

  # Function Bindings

  # Initialize context with params
  attach_function :whisper_init_from_file_with_params, [:string, WhisperContextParams.by_value], :pointer

  # Get default context params
  attach_function :whisper_context_default_params, [], WhisperContextParams.by_value

  # Get default full params
  attach_function :whisper_full_default_params, [:int], WhisperFullParams.by_value

  # Free functions
  attach_function :whisper_free, [:pointer], :void

  # Full transcription function
  attach_function :whisper_full, [:pointer, WhisperFullParams.by_value, :pointer, :int], :int

  # Number of segments
  attach_function :whisper_full_n_segments, [:pointer], :int

  # Get segment text
  attach_function :whisper_full_get_segment_text, [:pointer, :int], :string

  # Get segment start and end times
  attach_function :whisper_full_get_segment_t0, [:pointer, :int], :int64
  attach_function :whisper_full_get_segment_t1, [:pointer, :int], :int64
end

