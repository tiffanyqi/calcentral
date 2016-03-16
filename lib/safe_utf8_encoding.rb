module SafeUtf8Encoding
  extend self

  def safe_utf8(str)
    # This is the same encode method used by #to_json; call it early to catch errors.
    str.encode 'UTF-8'
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    # If we have trouble converting it to UTF-8, it might be UTF-8 already.
    encoded_copy = String.new(str).force_encoding 'UTF-8'
    if encoded_copy.valid_encoding?
      encoded_copy
    else
      # Do a best-effort encoding, skipping mystery characters.
      str.encode('UTF-8', 'ASCII-8BIT', invalid: :replace, undefined: :replace, replace: '')
    end
  end
end
