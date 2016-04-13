describe User::SearchUsersByName do
  let(:name) { nil }
  let(:roles_filter) { [] }
  subject { User::SearchUsersByName.new.search_by name, { include_guest_users: true, roles: roles_filter } }

  context 'perform no search if input is empty' do
    context 'nil input' do
      it { should be_empty }
    end
    context 'blank input' do
      let(:name) { '    ' }
      it { should be_empty }
    end
    context '\'Mr.\' and nothing else' do
      let(:name) { 'Mr.' }
      it { should be_empty }
    end
  end

  context 'search all permutations of name' do
    before do
      expect(Net::LDAP::Filter).to receive(:eq).with('displayname', 'man* jo*')
      expect(Net::LDAP::Filter).to receive(:eq).with('displayname', 'jo* man*')
      expect(Net::LDAP).to receive(:new).and_return (ldap = double)
      expect(ldap).to receive(:search).exactly(4).times.and_return []
    end
    context 'discard \'Jr.\'' do
      let(:name) { ' man Jr., jo' }
      it { should be_empty }
    end
    context 'discard \'M.A.\'' do
      let(:name) { 'Jo  MAN M.A.' }
      it { should be_empty }
    end
  end

  context 'filter by role' do
    let(:name) { random_name }
    let(:roles_filter) { [:student, :recentStudent] }
    before {
      allow(CalnetLdap::Client).to receive(:new).and_return (client = double)
      ldap_records = [:faculty, :student, :staff, :recentStudent, :exStudent]
      allow(client).to receive(:search_by_name).with(name, true).and_return ldap_records
      ldap_records.each do |record|
        # To avoid a complex spec, each ldap_record translate very nicely into a user role.
        user_roles = { roles: { record => true } }
        allow_any_instance_of(CalnetLdap::Parser).to receive(:parse).with(record).and_return user_roles
      end
    }
    it {
      two_students = [ { roles: {student: true} }, { roles: {recentStudent: true} } ]
      should eq two_students
    }
  end

end
