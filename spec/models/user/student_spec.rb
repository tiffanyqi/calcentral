describe User::Student do

  class StudentTestClass < BaseProxy; include User::Student; end

  before do
    allow(CalnetLdap::UserAttributes).to receive(:new).and_return double(get_feed: ldap_attributes)
    allow(CampusOracle::UserAttributes).to receive(:new).and_return double(get_feed: oracle_attributes)
  end

  let(:ldap_attributes) { {ldap_uid: uid, student_id: ldap_student_id} }
  let(:oracle_attributes) { {'ldap_uid' => uid, 'student_id' => oracle_student_id} }
  let(:uid) { '61889' }
  let(:ldap_student_id) { '11667051' }
  let(:oracle_student_id) { '99999999' }

  context 'student ID lookup' do
    subject { StudentTestClass.new(double(fake: true), user_id: uid).lookup_student_id }
    context 'when both LDAP and Oracle student ID attributes are present' do
      it { should eq ldap_student_id }
    end
    context 'when LDAP student ID attribute is missing' do
      let(:ldap_attributes) { {ldap_uid: uid} }
      it { should eq oracle_student_id }
    end
    context 'when LDAP student ID attribute is blank' do
      let(:ldap_attributes) { {ldap_uid: uid, student_id: ''} }
      it { should eq oracle_student_id }
    end
  end

  context 'legacy student check' do
    subject { StudentTestClass.new(double(fake: true), user_id: uid).legacy_student? }
    let(:legacy_id) { '12345678' }
    let(:cs_id) { '9876543210' }
    before do
      allow_any_instance_of(CalnetCrosswalk::ByUid).to receive(:lookup_campus_solutions_id).and_return campus_solutions_id
    end
    context 'ten-digit CS ID' do
      let(:campus_solutions_id) { cs_id }
      it { should be_falsey }
    end
    context 'eight-digit legacy ID' do
      let(:campus_solutions_id) { legacy_id }
      it { should be_truthy }
    end
    context 'Campus Solutions ID unavailable' do
      let(:campus_solutions_id) { nil }
      context 'eight-digit LDAP SID' do
        let(:ldap_student_id) { legacy_id }
        it { should be_truthy }
      end
      context 'ten-digit LDAP SID' do
        let(:ldap_student_id) { cs_id }
        it { should be_falsey }
      end
      context 'SID unavailable' do
        let(:ldap_student_id) { nil }
        let(:oracle_student_id) { nil }
        it { should be_falsey }
      end
    end
  end
end
