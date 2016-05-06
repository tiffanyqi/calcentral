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

    context 'wildcard usage' do
      it 'should reject a wildcard-only search' do
        expect { proxy.search_by '  * ' }.to raise_error
        expect { proxy.search_by '*?' }.to raise_error
      end
      it 'should allow phrase plus wildcard' do
        expect(proxy.send :only_special_characters?, 'Barack*').to be false
        expect(proxy.send :only_special_characters?, 'Barack * Obama').to be false
        expect(proxy.send :only_special_characters?, 'Barry O*').to be false
      end
    end

    context 'expected API arguments' do
      let(:name) { nil }
      subject { proxy.send :search_by_name_options, name }

      before(:each) do
        expect(proxy.send :only_special_characters?, name).to be false
      end

      context 'name is a single token' do
        let(:name) { 'Barack' }
        it 'should only set :name_1' do
          expect(subject[:name_1]).to eq 'Barack'
          expect(subject[:name_2]).to be_nil
        end
      end
      context 'two tokens, without comma' do
        let(:name) { 'Barack H. Obama' }
        it 'should set :name_1 and :name_2' do
          expect(subject[:name_1]).to eq 'Barack'
          expect(subject[:name_2]).to eq 'Obama'
        end
      end
      context 'first comma matters' do
        let(:name) { 'Obama II, Barack Hussein' }
        it 'should separate out last-name' do
          expect(subject[:name_1]).to eq 'Barack Hussein'
          expect(subject[:name_2]).to eq 'Obama II'
        end
      end
      context 'generational titles' do
        let(:name) { 'Obama Jr., Barack' }
        it 'should drop the Jr.' do
          expect(subject[:name_1]).to eq 'Barack'
          expect(subject[:name_2]).to eq 'Obama'
        end
      end
      context 'token count is 3 or more' do
        let(:name) { 'Mr. Barack Hussein Obama II' }
        it 'should assume the leading two tokens are first-name and middle-name' do
          expect(subject[:name_1]).to eq 'Barack Hussein'
          expect(subject[:name_2]).to eq 'Obama II'
        end
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
        expect(ldap).to receive(:search).exactly(2).times.and_return []
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
