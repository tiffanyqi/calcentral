module CampusOracle
  class UserAttributes < BaseProxy
    include Berkeley::UserRoles
    include Cache::UserCacheExpiry

    def initialize(options = {})
      super(Settings.campusdb, options)
    end

    def get_feed
      # Because this data structure is used by multiple top-level feeds, it's essential
      # that it be cached efficiently.
      self.class.fetch_from_cache @uid do
        get_feed_internal
      end
    end

    # TODO Eliminate mix of string keys and symbol keys.
    def get_feed_internal
      sis_current_term = Berkeley::Terms.fetch.sis_current_term
      result = CampusOracle::Queries.get_person_attributes(@uid)
      if result
        result[:roles] = roles_from_campus_row result
        result
      else
        {}
      end
    end

  end
end
