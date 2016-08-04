module Advising
  class MyAdvising < UserSpecificModel

    include Cache::CachedFeed
    include Cache::FeedExceptionsHandled
    include Cache::UserCacheExpiry
    include User::Student

    def get_feed_internal
      advising_feed = {
        feed: {},
        statusCode: 200
      }
      merge advising_feed if Settings.features.advising
      advising_feed
    end

    FEED_COMPONENTS = {
      advisorRelationships: CampusSolutions::AdvisorStudentRelationship,
      advisorActionItems: CampusSolutions::AdvisorStudentActionItems,
      advisorAppointments: CampusSolutions::AdvisorStudentAppointmentCalendar
    }

    def merge(advising_feed)
      FEED_COMPONENTS.each do |key, proxy_class|
        response = proxy_class.new(user_id: @uid).get
        if !response || !response[:feed] || response[:errored]
          advising_feed[:statusCode] = 500
          advising_feed[:errored] = true
          logger.error("Got errors in merged MyAdvising feed on #{proxy_class} for uid #{@uid} with response #{response}")
        else
          advising_feed[:feed][key] = response[:feed]
        end
      end
    end

  end
end
