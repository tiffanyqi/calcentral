describe User::Student do

  class StudentTestClass < BaseProxy; include User::Student; end

  context 'student ID lookup' do
    let(:uid) { '61889' }
    subject { StudentTestClass.new(double(fake: true), user_id: uid).lookup_student_id }

    before do
      allow(CalnetLdap::UserAttributes).to receive(:new).and_return double(get_feed: ldap_attributes)
      allow(CampusOracle::UserAttributes).to receive(:new).and_return double(get_feed: oracle_attributes)
    end

    let(:ldap_attributes) { {ldap_uid: uid, student_id: ldap_student_id} }
    let(:oracle_attributes) { {'ldap_uid' => uid, 'student_id' => oracle_student_id} }

    let(:ldap_student_id) { '11667051' }
    let(:oracle_student_id) { '99999999' }

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
end
