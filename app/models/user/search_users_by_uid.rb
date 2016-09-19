module User
  class SearchUsersByUid
    extend Cache::Cacheable
    include User::Parser

    def initialize(options={})
      @options = options
    end

    def search_users_by_uid
      # TODO Try reading User::Api cache first.
      user = self.class.fetch_from_cache @options[:id] do
        User::AggregatedAttributes.new(@options[:id]).get_feed
      end
      user if !user[:unknown] && has_role(user, @options[:roles])
    end

  end
end
