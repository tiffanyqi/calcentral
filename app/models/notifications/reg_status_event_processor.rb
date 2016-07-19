module Notifications
  class RegStatusEventProcessor < AbstractEventProcessor
    include ClassLogger

    def accept?(event)
      return false unless super event
      event["topic"] == "Bearfacts:RegStatus"
    end

    def process_internal(event, timestamp)
      logger.error "Got unexpected Bearfacts:Regstatus event! Ignoring #{event}"
      return []
    end

  end
end
