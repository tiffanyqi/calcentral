module CustomMatchers
  class HaveKeys
    def initialize(expected_keys)
      @expected_keys = expected_keys
      @missing_columns = []
    end

    def matches?(target)
      @target = target
      @missing_columns = @expected_keys.reject { |column| target.to_h.has_key? column }
      @missing_columns.count == 0
    end

    def missing_columns_string
      @missing_columns.collect {|c| "'#{c}'" }.join(', ')
    end

    def failure_message
      "expected #{@target.inspect} to include #{"column".pluralize(@missing_columns.count)}: #{missing_columns_string}"
    end

    def failure_message_when_negated
      failure_message
    end
  end

  def have_keys(expected_keys)
    HaveKeys.new(expected_keys)
  end
end
