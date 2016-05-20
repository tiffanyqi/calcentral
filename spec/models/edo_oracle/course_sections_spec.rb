describe EdoOracle::CourseSections do

  let(:term_id) { '2168' }
  let(:course_id) { random_id }
  let(:proxy) { described_class.new term_id, course_id }
  subject { proxy.get_section_data }

  context 'translate location' do
    shared_examples 'an intelligent parser of EDO db \'location\'' do
      it 'should properly split \'location\' value' do
        meeting = {
          'location' => location
        }
        result = proxy.send :translate_location, meeting
        expect(result[:buildingName]).to eq building_name
        expect(result[:roomNumber]).to eq room_number
      end
    end
    pending do
      it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
        let(:location) { 'Pauley Ballroom' }
        let(:building_name) { 'Pauley Ballroom' }
        let(:room_number) { nil }
      end
      it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
        let(:location) { 'Off Campus' }
        let(:building_name) { 'Off Campus' }
        let(:room_number) { nil }
      end
    end
    it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
      let(:location) { 'Internet/Online' }
      let(:building_name) { 'Internet/Online' }
      let(:room_number) { nil }
    end
    it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
      let(:location) { '2195 Hearst 330C' }
      let(:building_name) { '2195 Hearst' }
      let(:room_number) { '330C' }
    end
    it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
      let(:location) { 'Genetics & Plant Bio 104' }
      let(:building_name) { 'Genetics & Plant Bio' }
      let(:room_number) { '104' }
    end
    it_should_behave_like 'an intelligent parser of EDO db \'location\'' do
      let(:location) { 'Unit 3 Spens-Black 3' }
      let(:building_name) { 'Unit 3 Spens-Black' }
      let(:room_number) { '3' }
    end
  end

  context 'working EDO connection' do
    before do
      expect(EdoOracle::Queries).to receive(:get_section_meetings).with(term_id, course_id).and_return meetings
      expect(EdoOracle::Queries).to receive(:get_section_instructors).with(term_id, course_id).and_return instructors
    end

    let(:instructors) { [] }
    let(:meetings) { [] }

    context 'no instructors or meetings found' do
      its([:instructors]) { should be_empty }
      its([:schedules]) { should be_empty }
    end

    context 'meeting data' do
      let(:meetings) do
        [
          {
            'location' => 'WHEELER 0233',
            'meeting_days' => 'MOWEFR',
            'meeting_start_time' => '09:30',
            'meeting_end_time' => '10:59'
          },
          {
            'location' => 'Requested General Assignment',
            'meeting_days' => 'TUTH',
            'meeting_start_time' => '14:00',
            'meeting_end_time' => '14:59'
          },
          {
            'location' => nil,
            'meeting_days' => nil,
            'meeting_start_time' => nil,
            'meeting_end_time' => nil
          }
        ]
      end
      it 'ignores empty rows' do
        expect(subject[:schedules]).to have(2).items
      end
      it 'translates time' do
        expect(subject[:schedules][0][:schedule]).to eq 'MWF 9:30A-10:59A'
        expect(subject[:schedules][1][:schedule]).to eq 'TuTh 2:00P-2:59P'
      end
      it 'translates space' do
        expect(subject[:schedules][0][:buildingName]).to eq 'WHEELER'
        expect(subject[:schedules][0][:roomNumber]).to eq '233'
        expect(subject[:schedules][1][:buildingName]).to eq 'Room not yet assigned'
        expect(subject[:schedules][1][:roomNumber]).to be_blank
      end
    end

    context 'instructor data' do
      let(:instructors) do
        [
          {
            'ldap_uid' => '2040',
            'person_name' => 'Albertus Magnus',
            'role_code' => 'PI'
          },
          {
            'ldap_uid' => '242881',
            'person_name' => 'Thomas Aquinas',
            'role_code' => 'TNIC'
          }
        ]
      end
      it 'translates attributes' do
        expect(subject[:instructors]).to eq [
          {
            name: 'Albertus Magnus',
            role: 'PI',
            uid: '2040'
          },
          {
            name: 'Thomas Aquinas',
            role: 'TNIC',
            uid: '242881'
          }
        ]
      end
    end
  end

  context 'EDO DB errors' do
    before do
      allow(Settings.edodb).to receive(:fake).and_return false
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::JdbcAdapter).to receive(:select_all)
        .and_raise ActiveRecord::JDBCError, 'Primary key swiped by highwaymen'
    end
    it 'logs errors and returns empty results' do
      expect(Rails.logger).to receive(:error).with(/JDBCError/).at_least :once
      expect(subject[:instructors]).to be_empty
      expect(subject[:schedules]).to be_empty
    end
  end
end
