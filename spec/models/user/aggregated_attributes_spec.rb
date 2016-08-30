describe User::AggregatedAttributes do
  let(:uid) { random_id }
  let(:campus_solutions_id) { random_cs_id }
  let(:legacy_student_id) { random_id }
  let(:preferred_name) { 'Grigori Rasputin' }
  let(:bmail_from_edo) { 'rasputin@berkeley.edu' }
  let(:edo_attributes) do
    {
      person_name: preferred_name,
      student_id: campus_solutions_id,
      campus_solutions_id: campus_solutions_id,
      is_legacy_student: false,
      official_bmail_address: bmail_from_edo,
      roles: {
        student: true,
        exStudent: false,
        faculty: false,
        staff: false
      }
    }
  end
  let(:ldap_attributes) do
    {
      roles: {
        recentStudent: true
      }
    }
  end

  subject { User::AggregatedAttributes.new(uid).get_feed }

  before(:each) do
    allow(HubEdos::UserAttributes).to receive(:new).with(user_id: uid).and_return double get: edo_attributes
    allow(CalnetLdap::UserAttributes).to receive(:new).with(user_id: uid).and_return double get_feed: ldap_attributes
    allow(CampusOracle::UserAttributes).to receive(:new).with(user_id: uid).and_return double(get_feed: {})
  end

  describe 'all systems available' do
    context 'Hub feed' do
      it 'should return edo user attributes' do
        expect(subject[:isLegacyStudent]).to be false
        expect(subject[:sisProfileVisible]).to be true
        expect(subject[:officialBmailAddress]).to eq bmail_from_edo
        expect(subject[:campusSolutionsId]).to eq campus_solutions_id
        expect(subject[:studentId]).to eq campus_solutions_id
        expect(subject[:roles][:recentStudent]).to be true
      end
    end
  end

  describe 'LDAP is fallback' do
    let(:bmail_from_ldap) { 'raspy@berkeley.edu' }
    let(:ldap_attributes) do
      {
        official_bmail_address: bmail_from_ldap,
        roles: {
          student: is_active_student,
          exStudent: !is_active_student,
          recentStudent: !is_active_student,
          faculty: false,
          staff: true
        }
      }
    end
    context 'active student' do
      let(:is_active_student) { true }
      it 'should prefer EDO' do
        expect(subject[:officialBmailAddress]).to eq bmail_from_edo
        expect(subject[:roles][:recentStudent]).to be false
      end
    end
    context 'former student' do
      let(:is_active_student) { false }
      it 'should fall back to LDAP' do
        expect(subject[:officialBmailAddress]).to eq bmail_from_ldap
        expect(subject[:roles][:recentStudent]).to be true
      end
    end
    context 'applicant' do
      let(:edo_attributes) do
        {
          person_name: preferred_name,
          student_id: campus_solutions_id,
          campus_solutions_id: campus_solutions_id,
          official_bmail_address: bmail_from_edo,
          roles: {
            student: false,
            exStudent: false,
            faculty: false,
            staff: true,
            applicant: true
          }
        }
      end
      let(:is_active_student) { false }
      it 'should prefer EDO' do
        expect(subject[:officialBmailAddress]).to eq bmail_from_edo
        expect(subject[:roles][:recentStudent]).to be true
      end
    end
    context 'graduate' do
      let(:edo_attributes) do
        {
          person_name: preferred_name,
          student_id: campus_solutions_id,
          campus_solutions_id: campus_solutions_id,
          official_bmail_address: bmail_from_edo,
          roles: {
            student: false,
            exStudent: false,
            faculty: false,
            staff: true,
            graduate: true
          }
        }
      end
      let(:is_active_student) { true }
      it 'picks up EDO role' do
        expect(subject[:roles][:graduate]).to be true
      end
    end
    context 'broken Hub API' do
      let(:is_active_student) { true }
      let(:edo_attributes) do
        {
          body: 'An unknown server error occurred',
          statusCode: 503
        }
      end
      it 'relies on LDAP and Oracle' do
        expect(subject[:officialBmailAddress]).to eq bmail_from_ldap
        expect(subject[:roles][:recentStudent]).to be false
      end
    end
  end

end
