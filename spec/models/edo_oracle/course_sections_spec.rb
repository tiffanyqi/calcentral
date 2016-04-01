describe EdoOracle::CourseSections do

  let(:term_id) { '2168' }
  let(:course_id) { random_id }
  subject { described_class.new(term_id, course_id).get_section_data }

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
            'location' => nil,
            'meeting_days' => nil,
            'meeting_start_time' => nil,
            'meeting_end_time' => nil
          }
        ]
      end
      it 'ignores empty rows' do
        expect(subject[:schedules]).to have(1).item
      end
      it 'translates time' do
        expect(subject[:schedules].first[:schedule]).to eq 'MWF 09:30-10:59'
      end
      it 'translates space' do
        expect(subject[:schedules].first[:buildingName]).to eq 'WHEELER'
        expect(subject[:schedules].first[:roomNumber]).to eq '233'
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
      allow(EdoOracle::Queries).to receive(:get_section_instructors)
        .and_raise ActiveRecord::JDBCError, 'Primary key swiped by highwaymen'
    end
    it 'logs errors and returns a blank hash' do
      expect(Rails.logger).to receive(:error).with /JDBCError/
      expect(subject).to eq({})
    end
  end
end
