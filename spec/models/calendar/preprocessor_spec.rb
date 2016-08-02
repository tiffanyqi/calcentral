describe Calendar::Preprocessor do

  shared_examples 'it has a non-empty array of ClassCalendarQueue entries' do
    it 'each entry has the expected mandatory event data fields' do
      expect(subject).to be_present
      subject.each do |entry|
        expect(entry).to be_instance_of(Calendar::QueuedEntry)
        expect(entry.transaction_type).to be
        json = JSON.parse entry.event_data
        expect(json['location']).to be
        expect(json['summary']).to be
        expect(json['start']['dateTime']).to be
        expect(json['end']['dateTime']).to be
        expect(json['attendees']).to be
        expect(json['guestsCanSeeOtherGuests']).to be_falsey
        expect(json['guestsCanInviteOthers']).to be_falsey
        expect(json['locked']).to be_truthy
        expect(json['visibility']).to eq 'private'
        expect(json['recurrence'].length).to eq 1
      end
    end
  end

  describe '#get_entries from EDO DB data' do
    subject { Calendar::Preprocessor.new.get_entries }

    before do
      allow(CampusOracle::Calendar).to receive(:get_all_courses).and_return []
      allow(EdoOracle::Calendar).to receive(:get_all_courses).and_return courses
      expect(EdoOracle::Calendar).to receive(:get_whitelisted_students).with(Calendar::User.all, '2168', '17309').and_return whitelisted_students
    end
    let(:courses) do
      [{
        'term_id' => '2168',
        'session_id' => '1',
        'section_id' => '17309',
        'section_display_name' => 'Dancing With Deontologists',
        'instruction_format' => 'LAB',
        'section_num' => '001',
        'meeting_num' => '1',
        'location' => 'Pauley Ballroom',
        'meeting_days' => 'MOWEFR',
        'meeting_start_time' => '14:00',
        'meeting_end_time' => '14:59',
        'meeting_start_date' => Time.parse('2016-08-24 00:00:00 UTC'),
        'meeting_end_date' => Time.parse('2016-12-09 00:00:00 UTC')
      }]
    end

    context 'no users in whitelist' do
      let(:whitelisted_students) { [] }
      it { should be_empty }
    end

    context 'non-enrolled student in whitelist' do
      before { Calendar::User.create(uid: '1') }
      let(:whitelisted_students) { [] }
      it { should be_empty }
    end

    context 'no users in whitelist, but an event was created before the whitelist became empty' do
      before do
        Calendar::LoggedEntry.create({
          year: 2016,
          term_cd: 'D',
          ccn: 17309,
          multi_entry_cd: '1',
          transaction_type: Calendar::QueuedEntry::CREATE_TRANSACTION,
          event_data: {foo: 123}.to_json,
          event_id: 'abcdef'
        })
      end
      let(:whitelisted_students) { [] }
      it 'returns an array with at least 1 delete transaction on it' do
        expect(subject[0].transaction_type).to eq 'D'
        expect(subject[0].event_id).to eq 'abcdef'
      end
    end

    context 'when the whitelist has an enrolled student on it' do
      before { Calendar::User.create({uid: '300939'}) }
      let(:whitelisted_students) { [{'ldap_uid' => '300939', 'official_bmail_address' => 'tammi.chang.clc@gmail.com'}] }

      context 'when a logged entry exists from a previous run' do
        before do
          Calendar::LoggedEntry.create({
            year: 2016,
            term_cd: 'D',
            ccn: 17309,
            multi_entry_cd: '1',
            job_id: 5,
            event_id: 'abcdef'
          })
        end
        it_behaves_like 'it has a non-empty array of ClassCalendarQueue entries'
        it 'uses EDO DB-provided email address' do
          json = JSON.parse(subject[0].event_data)
          expect(json['attendees'][0]['email']).to eq 'tammi.chang.clc@gmail.com'
        end
        it 'returns the event_id of a logged entry from a previous run' do
          expect(subject[0].event_id).to eq 'abcdef'
          expect(subject[0].transaction_type).to eq 'U'
        end
      end

      context 'when a preprocess task has been run twice without running export' do
        before do
          Calendar::QueuedEntry.create({
            year: 2016,
            term_cd: 'D',
            ccn: 17309,
            multi_entry_cd: '1',
            event_id: 'abcdef'
          })
        end
        let!(:old_entry_id) { Calendar::QueuedEntry.first.id }
        it 'has the same queued_entry_id as the previous run of preprocess' do
          expect(subject[0].id).to eq old_entry_id
        end
      end

      context 'when the user whitelist has an enrolled student with alternate email for test purposes' do
        before { Calendar::User.first.update(alternate_email: 'tammi@testg.berkeley.edu.test-google-a.com') }
        it_behaves_like 'it has a non-empty array of ClassCalendarQueue entries'
        it 'queues up event creation with correct times and locations' do
          json = JSON.parse(subject[0].event_data)
          expect(json['location']).to eq 'Pauley Ballroom, Berkeley, CA'
          expect(json['start']['dateTime']).to eq '2016-08-24T14:00:00.000-07:00'
          expect(json['end']['dateTime']).to eq '2016-08-24T14:59:00.000-07:00'
          expect(json['recurrence'][0]).to eq 'RRULE:FREQ=WEEKLY;UNTIL=20161209T000000Z;BYDAY=MO,WE,FR'
          expect(json['attendees'].length).to eq 1
          expect(json['attendees'][0]['email']).to eq 'tammi@testg.berkeley.edu.test-google-a.com'
          expect(subject[0].multi_entry_cd).to eq '1'
          expect(subject[0].transaction_type).to eq 'C'
        end
      end

      context 'enrollment with no attached bmail address' do
        let(:whitelisted_students) { [{'ldap_uid' => '300939', 'official_bmail_address' => nil}] }
        before do
          Calendar::User.create(uid: '300939')
          allow_any_instance_of(CalnetLdap::UserAttributes).to receive(:get_feed).and_return(
            official_bmail_address: ldap_bmail_address)
        end
        context 'bmail address available from LDAP' do
          let(:ldap_bmail_address) { 'tammi.chang.from.ldap@gmail.com' }
          it 'queues an event entry with the LDAP address' do
            json = JSON.parse(subject[0].event_data)
            expect(json['attendees'][0]['email']).to eq ldap_bmail_address
          end
        end
        context 'no bmail address available from LDAP' do
          let(:ldap_bmail_address) { nil }
          it 'queues no event entries' do
            expect(subject).to be_empty
          end
        end
      end

      context 'when a course exists but has no schedule data' do
        let(:courses) do
          [{
            'term_id' => '2168',
            'session_id' => '1',
            'section_id' => '17309',
            'section_display_name' => 'Dancing With Deontologists',
            'instruction_format' => 'LAB',
            'section_num' => '001',
            'meeting_num' => '1',
            'location' => 'Pauley Ballroom'
          }]
        end
        it { should be_empty }
      end
    end
  end

  # TODO This test suite substantially duplicates the EDO DB test suite above. It should be removed in its entirety once
  # legacy Oracle data is no longer powering the current term.
  describe '#get_entries from legacy Oracle data' do
    subject { Calendar::Preprocessor.new.get_entries }
    context 'when the user whitelist is empty' do
      it 'returns an empty list' do
        expect(subject).to be
      end
    end
    context 'when the user whitelist has a non-enrolled student on it' do
      before do
        Calendar::User.create({uid: '1'})
      end
      it 'returns an empty array' do
        expect(subject).to be
      end
    end
    context 'when the user whitelist is empty, but an event was created before the whitelist became empty', if: CampusOracle::Calendar.test_data? do
      before do
        Calendar::LoggedEntry.create(
          {
            year: 2013,
            term_cd: 'D',
            ccn: 7309,
            multi_entry_cd: 'A',
            transaction_type: Calendar::QueuedEntry::CREATE_TRANSACTION,
            event_data: {foo: 123}.to_json,
            event_id: 'abcdef'})
      end
      it 'returns an array with at least 1 delete transaction on it' do
        expect(subject[0].transaction_type).to eq 'D'
        expect(subject[0].event_id).to eq 'abcdef'
      end
    end
    context 'when the whitelist has an enrolled student on it', if: CampusOracle::Calendar.test_data? do
      before do
        Calendar::User.create({uid: '300939'})

        Calendar::LoggedEntry.create(
          {
            year: 2013,
            term_cd: 'D',
            ccn: 7309,
            multi_entry_cd: 'A',
            job_id: 5,
            event_id: 'abcdef'})
      end
      it_behaves_like 'it has a non-empty array of ClassCalendarQueue entries'
      it 'has tammis default alternateid from fake Oracle' do
        json = JSON.parse(subject[0].event_data)
        expect(json['attendees'][0]['email']).to eq 'tammi.chang.clc@gmail.com'
      end
      it 'returns the event_id of a logged entry from a previous run' do
        expect(subject[0].event_id).to eq 'abcdef'
        expect(subject[0].transaction_type).to eq 'U'
      end
    end
    context 'when a student on the whitelist is enrolled in a summer course', if: CampusOracle::Calendar.test_data? do
      before(:each) {
        Calendar::User.create({uid: '300939'})
        Settings.terms.stub(:fake_now).and_return(DateTime.parse('2014-03-10'))
        Berkeley::SummerSubTerm.create(
          year: 2014, sub_term_code: 5, start: Date.new(2014, 5, 26), end: Date.new(2014, 7, 2))
      }
      it 'has the meeting place and times for the summer Biology course from test data' do
        json = JSON.parse(subject[0].event_data)
        expect(json['location']).to eq '2030 Valley Life Sciences Building, Berkeley, CA'
        expect(json['start']['dateTime']).to eq '2014-05-26T16:00:00.000-07:00'
        expect(json['end']['dateTime']).to eq '2014-05-26T17:00:00.000-07:00'
        expect(json['recurrence'][0]).to eq 'RRULE:FREQ=WEEKLY;UNTIL=20140703T065959Z;BYDAY=MO'
      end
      it_behaves_like 'it has a non-empty array of ClassCalendarQueue entries'
    end
    context 'when a preprocess task has been run twice without running export', if: CampusOracle::Calendar.test_data? do
      let!(:old_entry_id) {
        old_entry = Calendar::QueuedEntry.create(
          {
            year: 2013,
            term_cd: 'D',
            ccn: 7309,
            multi_entry_cd: 'A',
            event_id: 'abcdef'})
        old_entry.id
      }
      before do
        Calendar::User.create({uid: '300939'})
      end
      it 'has the same queued_entry_id as the previous run of preprocess' do
        expect(subject[0].id).to eq old_entry_id
      end
    end
    context 'when the user whitelist has an enrolled student on it with an alternate email for test purposes', if: CampusOracle::Calendar.test_data? do
      before do
        Calendar::User.create({uid: '300939', alternate_email: 'ctweney@testg.berkeley.edu.test-google-a.com'})
      end
      it_behaves_like 'it has a non-empty array of ClassCalendarQueue entries'
      it 'has the meeting place and times for a multi-scheduled Biology 1a' do
        json = JSON.parse(subject[0].event_data)
        expect(json['location']).to eq '2030 Valley Life Sciences Building, Berkeley, CA'
        expect(json['start']['dateTime']).to eq '2013-09-02T16:00:00.000-07:00'
        expect(json['end']['dateTime']).to eq '2013-09-02T17:00:00.000-07:00'
        expect(json['recurrence'][0]).to eq 'RRULE:FREQ=WEEKLY;UNTIL=20131207T075959Z;BYDAY=MO'
        expect(json['attendees'].length).to eq 1
        expect(json['attendees'][0]['email']).to eq 'ctweney@testg.berkeley.edu.test-google-a.com'
        expect(subject[0].multi_entry_cd).to eq 'A'
        expect(subject[0].transaction_type).to eq 'C'

        json = JSON.parse(subject[1].event_data)
        expect(json['location']).to eq '60 Evans Hall, Berkeley, CA'
        expect(json['start']['dateTime']).to eq '2013-09-04T14:00:00.000-07:00'
        expect(json['end']['dateTime']).to eq '2013-09-04T15:00:00.000-07:00'
        expect(json['recurrence'][0]).to eq 'RRULE:FREQ=WEEKLY;UNTIL=20131207T075959Z;BYDAY=WE'
        expect(json['attendees'].length).to eq 1
        expect(json['attendees'][0]['email']).to eq 'ctweney@testg.berkeley.edu.test-google-a.com'
        expect(subject[1].multi_entry_cd).to eq 'B'
        expect(subject[1].transaction_type).to eq 'C'
      end
      it 'has the meeting place and times for Biology 1a' do
        expect(JSON.parse(subject[2].event_data)['location']).to eq '2030 Valley Life Sciences Building, Berkeley, CA'
        expect(subject[2].multi_entry_cd).to eq '-'
        expect(subject[2].transaction_type).to eq 'C'
      end
    end
    context 'when a course exists but its term cant be found' do
      before do
        CampusOracle::Calendar.stub(:get_all_courses).and_return([{
                                                               'term_yr' => 5070,
                                                               'term_cd' => 'B',
                                                               'course_cntl_num' => 12345
                                                             }])
      end
      it 'produces an empty list of entries' do
        expect(subject).to be_empty
      end

    end
    context 'when a course exists but it has no schedule' do
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
             'meeting_days' => ''
           }])
        CampusOracle::Calendar.stub(:get_whitelisted_students).and_return(
          [{
             'ldap_uid' => '1234',
             'official_bmail_address' => 'foo@foo.com'
           }])
        Calendar::User.create({uid: '1234'})
      end
      it 'produces an empty list' do
        expect(subject).to be_empty
      end
    end
  end

end
