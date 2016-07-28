module Calendar
  class QueuedEntry < ActiveRecord::Base

    CREATE_TRANSACTION = 'C'
    UPDATE_TRANSACTION = 'U'
    DELETE_TRANSACTION = 'D'

    self.table_name = 'class_calendar_queue'

    attr_accessible :year, :term_cd, :ccn, :multi_entry_cd, :event_data, :event_id, :transaction_type

    # Transient attributes set before event data is serialized.
    attr_accessor :name, :location, :attendees, :schedule

    def self.from_legacy_row(row)
      logger.info "Preprocessing #{row['course_name']} ccn = #{row['term_yr']}-#{row['term_cd']}-#{row['course_cntl_num']}, multi_entry_cd = #{row['multi_entry_cd']}"
      return nil unless (schedule = Calendar::Schedule::CampusOracle.from_meeting_data row)

      entry = self.where(
        year: row['term_yr'],
        term_cd: row['term_cd'],
        ccn: row['course_cntl_num'],
        multi_entry_cd: row['multi_entry_cd'].blank? ? '-' : row['multi_entry_cd']
      ).first_or_initialize

      entry.name = row['course_name']
      entry.schedule = schedule

      if (building_name = row['building_name']).present?
        building_translation = Berkeley::Buildings.get building_name
        building_name = building_translation['display'] if building_translation.present?
        entry.location = "#{row['room_number'].to_s.gsub(/^0+/, '')} #{building_name}, Berkeley, CA"
      end

      entry
    end

    def self.from_edo_row(row)
      logger.info "Preprocessing #{row['section_display_name']}; section_id = #{row['section_id']}; term_id = #{row['term_id']}; meeting_num = #{row['meeting_num']}"
      return nil unless (schedule = Calendar::Schedule::EdoOracle.from_meeting_data row)

      term_code = Berkeley::TermCodes.from_edo_id row['term_id']

      entry = self.where(
        year: term_code[:term_yr],
        term_cd: term_code[:term_cd],
        ccn: row['section_id'],
        # The name 'multi_entry_cd' is a carry-over from a legacy Oracle column. We use it to
        # disambiguate multiple meeting entries for the same class section.
        multi_entry_cd: row['meeting_num'].to_s
      ).first_or_initialize

      entry.name = row['section_display_name']
      entry.schedule = schedule
      entry.location = "#{row['location']}, Berkeley, CA" if row['location'].present?

      entry
    end

    def preprocess
      if (self.transaction_type = set_transaction_type) && (self.event_data = json_event_data)
        true
      end
    end

    private

    def set_transaction_type
      # First, check if we have already logged a Google event ID for this term, class and meeting.
      logged_entry = Calendar::LoggedEntry.lookup self

      if logged_entry.present? && logged_entry.event_id && logged_entry.transaction_type != Calendar::QueuedEntry::DELETE_TRANSACTION
        # We already have a Google event logged. Our job is either to update or to delete it.
        self.event_id = logged_entry.event_id
        if self.attendees.empty?
          logger.info 'Zero attendees, this will be a DELETE action'
          Calendar::QueuedEntry::DELETE_TRANSACTION
        elsif self.schedule[:start].blank?
          logger.info 'Blank class schedule, this will be a DELETE action'
          Calendar::QueuedEntry::DELETE_TRANSACTION
        else
          logger.info 'This will be an UPDATE action'
          Calendar::QueuedEntry::UPDATE_TRANSACTION
        end
      elsif self.attendees.present? && self.schedule[:start].present?
        # We don't have an existing Google event, but we do have data, so go ahead and create an event.
        Calendar::QueuedEntry::CREATE_TRANSACTION
      else
        # We don't have an existing Google event and we're missing data; do nothing.
        nil
      end
    end

    def json_event_data
      event_data = {
        summary: self.name,
        location: self.location,
        attendees: self.attendees,
        guestsCanSeeOtherGuests: false,
        guestsCanInviteOthers: false,
        locked: true,
        visibility: 'private'
      }
      event_data.merge! self.schedule
      JSON.pretty_generate event_data
    end

  end
end
