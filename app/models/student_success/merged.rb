module StudentSuccess
  class Merged

    include ClassLogger
    include MergedModel

    def initialize(opts={})
      @student_uid_param = opts[:user_id]
    end

    def self.providers
      [
        OutstandingBalance,
        TermGpa
      ]
    end

    def get_feed
      feed = {}
      handling_provider_exceptions(feed, self.class.providers) do |provider|
        provider.new(user_id: @student_uid_param).merge feed
      end
      feed
    end
  end
end
