describe 'Calendar integration full stack against EDO DB', testext: true do
  before do
    allow(EdoOracle::Calendar).to receive(:get_all_courses).and_return [{
      'term_id' => '2168',
      'session_id' => '1',
      'section_id' => '12345',
      'section_display_name' => 'Testing 1A',
      'instruction_format' => 'LEC',
      'section_num' => '001',
      'meeting_num' => '1',
      'location' => 'Pauley Ballroom',
      'meeting_days' => 'MOWEFR',
      'meeting_start_time' => '14:00',
      'meeting_end_time' => '14:59',
      'meeting_start_date' => Time.parse('2016-08-24 00:00:00 UTC'),
      'meeting_end_date' => Time.parse('2016-12-09 00:00:00 UTC')
    }]
    allow(EdoOracle::Calendar).to receive(:get_whitelisted_students).and_return [{
      'ldap_uid' => '904715',
      # TODO Should we be using a different test Google account for this spec?
      'official_bmail_address' => 'ctweney@testg.berkeley.edu.test-google-a.com'
    }]
    Calendar::User.create(uid: '904715')
  end

  let!(:get_proxy) do
    GoogleApps::EventsGet.new(
      access_token: Settings.class_calendar.access_token,
      refresh_token: Settings.class_calendar.refresh_token,
      expiration_time: DateTime.now.to_i + 3599
    )
  end

  context 'with a real working Google connection' do
    # Run in one big example to preserve database state.
    it 'should create, update and delete events' do

      # 1. CREATE ----------------------------------------------------------------------------------

      # Set up the queue.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::CREATE_TRANSACTION
      queued.each &:save

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # Export the queue (1 attendee; event CREATE).
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      first_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(first_job.error_count).to eq 0
      expect(first_job.total_entry_count).to eq 1

      saved_entry = Calendar::LoggedEntry.where({job_id: first_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq 'Pauley Ballroom, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2016-08-24T14:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2016-08-24T14:59:00-07:00'

      # 2. UPDATE ----------------------------------------------------------------------------------

      # Change the class location and time.
      allow(EdoOracle::Calendar).to receive(:get_all_courses).and_return [{
        'term_id' => '2168',
        'session_id' => '1',
        'section_id' => '12345',
        'section_display_name' => 'Testing 1A',
        'instruction_format' => 'LEC',
        'section_num' => '001',
        'meeting_num' => '1',
        'location' => 'Valley Life Sciences 100',
        'meeting_days' => 'MOWEFR',
        'meeting_start_time' => '16:00',
        'meeting_end_time' => '16:59',
        'meeting_start_date' => Time.parse('2016-08-24 00:00:00 UTC'),
        'meeting_end_date' => Time.parse('2016-12-09 00:00:00 UTC')
      }]

      # Preprocess again. This will create an UPDATE transaction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::UPDATE_TRANSACTION
      queued.each &:save

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # Export again.
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      second_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(second_job.error_count).to eq 0
      expect(second_job.total_entry_count).to eq 1

      # Make sure the event on Google has the updated location.
      saved_entry = Calendar::LoggedEntry.where({job_id: second_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq 'Valley Life Sciences 100, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2016-08-24T16:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2016-08-24T16:59:00-07:00'

      # 3. UPDATE AGAIN ----------------------------------------------------------------------------------

      # Change the class location once more and make sure it succeeds.
      allow(EdoOracle::Calendar).to receive(:get_all_courses).and_return [{
        'term_id' => '2168',
        'session_id' => '1',
        'section_id' => '12345',
        'section_display_name' => 'Testing 1A',
        'instruction_format' => 'LEC',
        'section_num' => '001',
        'meeting_num' => '1',
        'location' => 'Dwinelle 155',
        'meeting_days' => 'MOWEFR',
        'meeting_start_time' => '10:00',
        'meeting_end_time' => '10:59',
        'meeting_start_date' => Time.parse('2016-08-24 00:00:00 UTC'),
        'meeting_end_date' => Time.parse('2016-12-09 00:00:00 UTC')
      }]

      # Preprocess again. This should produce an UPDATE transaction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::UPDATE_TRANSACTION
      queued.each &:save

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # Export again.
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      third_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(third_job.error_count).to eq 0
      expect(third_job.total_entry_count).to eq 1

      # Make sure the event on Google has the updated location.
      saved_entry = Calendar::LoggedEntry.where({job_id: third_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq 'Dwinelle 155, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2016-08-24T10:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2016-08-24T10:59:00-07:00'

      # 4. DELETE EVENTS --------------------------------------------------------------------------------

      # Take the user off the whitelist.
      user = Calendar::User.where(uid: '904715')[0]
      user.delete
      allow(EdoOracle::Calendar).to receive(:get_whitelisted_students).and_return []

      # Preprocess again. This should produce a DELETE transaction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::DELETE_TRANSACTION
      queued.each &:save

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # Export again.
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      fourth_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(fourth_job.error_count).to eq 0
      expect(fourth_job.total_entry_count).to eq 1

      # Preprocess again. This should produce an empty list, since the event has already been deleted
      # and nobody is on the whitelist now.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 0
    end
  end
end

# TODO This test suite substantially duplicates the EDO DB test suite above. It should be removed in its entirety once
# legacy Oracle data is no longer powering the current term.
describe 'Calendar integration full stack against legacy Oracle', testext: true do
  before do
    CampusOracle::Calendar.stub(:get_all_courses).and_return(
      [{
         'term_yr' => 2013,
         'term_cd' => 'D',
         'course_cntl_num' => 12345,
         'course_name' => 'Testing 1A',
         'multi_entry_cd' => '',
         'building_name' => 'Dwinelle',
         'room_number' => '117',
         'meeting_days' => ' M W',
         'meeting_start_time' => '0200',
         'meeting_start_time_ampm_flag' => 'P',
         'meeting_end_time' => '0300',
         'meeting_end_time_ampm_flag' => 'P'
       }])
    CampusOracle::Calendar.stub(:get_whitelisted_students).and_return(
      [{
         'ldap_uid' => '904715',
         'official_bmail_address' => 'ctweney@testg.berkeley.edu.test-google-a.com'
       }])
    Calendar::User.create({uid: '904715'})
  end

  let!(:get_proxy) {
    GoogleApps::EventsGet.new(
      access_token: Settings.class_calendar.access_token,
      refresh_token: Settings.class_calendar.refresh_token,
      expiration_time: DateTime.now.to_i + 3599)
  }

  context 'with a real working Google connection' do

    it 'should create and then delete events' do

      # EVENT CREATES ------------------------------------------------------------------------------------
      # set up the queue
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::CREATE_TRANSACTION
      queued.each do |entry|
        entry.save
      end

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # export the queue (1 attendee; event CREATE)
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      first_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(first_job.error_count).to eq 0
      expect(first_job.total_entry_count).to eq 1

      saved_entry = Calendar::LoggedEntry.where({job_id: first_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq '117 Dwinelle Hall, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2013-09-02T14:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2013-09-02T15:00:00-07:00'

      # EVENT UPDATES ------------------------------------------------------------------------------------
      # change the class location and time
      CampusOracle::Calendar.stub(:get_all_courses).and_return(
        [{
           'term_yr' => 2013,
           'term_cd' => 'D',
           'course_cntl_num' => 12345,
           'course_name' => 'Testing 1A',
           'multi_entry_cd' => '',
           'building_name' => 'FOOTHILL',
           'room_number' => '100',
           'meeting_days' => ' M W',
           'meeting_start_time' => '0400',
           'meeting_start_time_ampm_flag' => 'P',
           'meeting_end_time' => '0500',
           'meeting_end_time_ampm_flag' => 'P'
         }])

      # now preprocess again. This will create an UPDATE transaction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::UPDATE_TRANSACTION
      queued.each do |entry|
        entry.save
      end

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # now export again
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      second_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(second_job.error_count).to eq 0
      expect(second_job.total_entry_count).to eq 1

      # now make sure the event on google has the updated location
      saved_entry = Calendar::LoggedEntry.where({job_id: second_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq '100 Foothill Student Housing, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2013-09-02T16:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2013-09-02T17:00:00-07:00'

      # EVENT SECOND UPDATES --------------------------------------------------------------------------------
      # now change the class location once more and make sure it succeeds.
      CampusOracle::Calendar.stub(:get_all_courses).and_return(
        [{
           'term_yr' => 2013,
           'term_cd' => 'D',
           'course_cntl_num' => 12345,
           'course_name' => 'Testing 1A',
           'multi_entry_cd' => '',
           'building_name' => 'Dwinelle',
           'room_number' => '155',
           'meeting_days' => ' M W',
           'meeting_start_time' => '0400',
           'meeting_start_time_ampm_flag' => 'P',
           'meeting_end_time' => '0500',
           'meeting_end_time_ampm_flag' => 'P'
         }])

      # now preprocess again. This will create an UPDATE transction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::UPDATE_TRANSACTION
      queued.each do |entry|
        entry.save
      end

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # now export again
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      third_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(third_job.error_count).to eq 0
      expect(third_job.total_entry_count).to eq 1

      # now make sure the event on google has the updated location
      saved_entry = Calendar::LoggedEntry.where({job_id: third_job.id}).first
      expect(saved_entry).to be
      event_id = saved_entry.event_id
      event_on_google = get_proxy.get_event event_id
      expect(event_on_google).to be
      json = JSON.parse(event_on_google.body)
      expect(json['location']).to eq '155 Dwinelle Hall, UC Berkeley'
      expect(json['start']['dateTime']).to eq '2013-09-02T16:00:00-07:00'
      expect(json['end']['dateTime']).to eq '2013-09-02T17:00:00-07:00'

      # EVENT DELETES ------------------------------------------------------------------------------------
      # now take the user off the whitelist
      user = Calendar::User.where({uid: '904715'})[0]
      user.delete
      CampusOracle::Calendar.stub(:get_whitelisted_students).and_return([])

      # now preprocess again. This should produce a DELETE transaction for the existing event.
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 1
      expect(queued[0].ccn).to eq 12345
      expect(queued[0].transaction_type).to eq Calendar::QueuedEntry::DELETE_TRANSACTION
      queued.each do |entry|
        entry.save
      end

      entries = Calendar::QueuedEntry.all
      expect(entries.length).to eq 1

      # now export again
      exported = Calendar::Exporter.new.ship_entries entries
      expect(exported).to be_truthy

      fourth_job = Calendar::Job.limit(1).order(id: :desc).first
      expect(fourth_job.error_count).to eq 0
      expect(fourth_job.total_entry_count).to eq 1

      # after EVENT DELETES -----------------------------------------------------------------------------
      # now preprocess again. This should produce an empty list (since the event has already been deleted,
      # and nobody is on the whitelist now).
      queued = Calendar::Preprocessor.new.get_entries
      expect(queued.length).to eq 0

    end

  end
end
