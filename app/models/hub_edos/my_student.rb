module HubEdos
  class MyStudent < UserSpecificModel

    include ClassLogger
    include Cache::CachedFeed
    include Cache::UserCacheExpiry
    # Needed to expire cache entries specific to Viewing-As users alongside original user's cache.
    include Cache::RelatedCacheKeyTracker
    include CampusSolutions::ProfileFeatureFlagged

    def get_feed_internal
      merged = {
        feed: {
          student: {}
        },
        statusCode: 200
      }
      return merged unless is_cs_profile_feature_enabled

      proxy_options = @options
      [HubEdos::MyContacts, HubEdos::MyDemographics, HubEdos::MyAffiliations].each do |proxy|
        hub_response = proxy.new(@uid, proxy_options).get_feed
        if hub_response[:errored]
          merged[:statusCode] = 500
          merged[:errored] = true
          logger.error("Got errors in merged student feed on #{proxy} for uid #{@uid} with response #{hub_response}")
        else
          merged[:feed][:student].merge!(hub_response[:feed]['student'])
        end
      end

      # When we don't have any identifiers for this student, we should send a 404 to the front-end
      if !merged[:errored] && !merged[:feed][:student]['identifiers']
        merged[:statusCode] = 404
        merged[:errored] = true
        logger.warn("No identifiers found for student feed uid #{@uid} with feed #{merged}")
      end

      merged
    end

    def instance_key
      Cache::KeyGenerator.per_view_as_type @uid, @options
    end

  end
end
