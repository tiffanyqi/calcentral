module HubEdos
  class MyStudent < UserSpecificModel

    include ClassLogger
    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include CampusSolutions::ProfileFeatureFlagged

    def get_feed_internal
      merged = {
        feed: {
          student: {}
        },
        statusCode: 200
      }
      return merged unless is_cs_profile_feature_enabled

      [HubEdos::Contacts, HubEdos::Demographics, HubEdos::Affiliations].each do |proxy|
        hub_response = proxy.new({user_id: @uid}).get
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

  end
end
