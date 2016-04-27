describe User::SearchUsersByName do
  let(:name) { nil }
  let(:roles) { [] }
  let(:opts) do
    {
      search_campus_solutions: search_campus_solutions,
      include_guest_users: true,
      roles: roles
    }
  end
  let(:proxy) { User::SearchUsersByName.new }
  subject { proxy.search_by name, opts }

  shared_examples 'a search with empty input' do
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

  context 'Campus Solutions search' do
    let(:search_campus_solutions) { true }

    it_should_behave_like 'a search with empty input'

    context 'expected API arguments' do
      it 'should only set :name_1 if name is a single token' do
        opts = proxy.send :search_by_name_options, 'Barack'
        expect(opts[:name_1]).to eq 'Barack'
        expect(opts[:name_2]).to be_nil
      end
      it 'should set :name_1 and :name_2 if name is two tokens, without comma' do
        opts = proxy.send :search_by_name_options, 'Barack H. Obama'
        expect(opts[:name_1]).to eq 'Barack'
        expect(opts[:name_2]).to eq 'Obama'
      end
      it 'should separate out last-name per first comma in name' do
        opts = proxy.send :search_by_name_options, 'Obama II, Barack Hussein'
        expect(opts[:name_1]).to eq 'Barack Hussein'
        expect(opts[:name_2]).to eq 'Obama II'
      end
      it 'should drop the Jr.' do
        opts = proxy.send :search_by_name_options, 'Obama Jr., Barack'
        expect(opts[:name_1]).to eq 'Barack'
        expect(opts[:name_2]).to eq 'Obama'
      end
      it 'should assume the leading two tokens are first-name and middle-name when token count is 3 or more' do
        opts = proxy.send :search_by_name_options, 'Mr. Barack Hussein Obama II'
        expect(opts[:name_1]).to eq 'Barack Hussein'
        expect(opts[:name_2]).to eq 'Obama II'
      end
    end

  end

  context 'LDAP search' do
    let(:search_campus_solutions) { false }

    it_should_behave_like 'a search with empty input'

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
        let(:name) { 'jo  man M.A.' }
        it { should be_empty }
      end
    end

    context 'filter by role' do
      let(:name) { random_name }
      let(:roles) { [:student, :recentStudent] }
      before {
        allow(CalnetLdap::Client).to receive(:new).and_return (client = double)
        ldap_records = [:faculty, :student, :staff, :recentStudent, :exStudent]
        allow(client).to receive(:search_by_name).with(name, true).and_return ldap_records
        ldap_records.each do |record|
          # To avoid a complex spec, each ldap_record translate very nicely into a user role.
          user_roles = { roles: { record => true } }
          allow_any_instance_of(User::Parser).to receive(:parse).with(record).and_return user_roles
        end
      }
      it 'should only match on student-related roles' do
        expect(subject).to have(2).items
        expect(subject[0]).to include(roles: { student: true })
        expect(subject[1]).to include(roles: { recentStudent: true })
      end
    end
  end

end
