describe CampusSolutions::DelegateStudents do
  let(:user_id) { '12347' }
  let(:proxy) { CampusSolutions::DelegateStudents.new(fake: true, user_id: user_id) }
  subject { proxy.get }

  it_should_behave_like 'a simple proxy that returns errors'
  it_should_behave_like 'a proxy that got data successfully'
  it_should_behave_like 'a proxy that properly observes the delegated access feature flag'

  context 'delegate is linked to two students' do
    let(:tom_uid) { random_id }
    let(:maggie_uid) { random_id }
    before do
      allow(CalnetCrosswalk::ByCsId).to receive(:new).with(user_id: '23009422').and_return (tom = double)
      allow(tom).to receive(:lookup_ldap_uid).and_return tom_uid
      allow(CalnetCrosswalk::ByCsId).to receive(:new).with(user_id: '24363318').and_return (maggie = double)
      allow(maggie).to receive(:lookup_ldap_uid).and_return maggie_uid
      %w(17986976 23623575 24346769 24549574 232132138971298721398231).each do |sid|
        allow(CalnetCrosswalk::ByCsId).to receive(:new).with(user_id: sid).and_return (proxy = double)
        allow(proxy).to receive(:lookup_ldap_uid).and_return random_id
      end
    end
    it 'returns expected mock data' do
      students = subject[:feed][:students]
      expect(students).to have_at_least(2).items
      tom = students.find {|s| s[:fullName] == 'Tom Tulliver' }
      expect(tom[:campusSolutionsId]).to eq '23009422'
      expect(tom[:uid]).to eq tom_uid
      expect(tom[:privileges]).to eq({ financial: false, viewEnrollments: false, viewGrades: false, phone: true })
      maggie = students.find {|s| s[:fullName] == 'Maggie Tulliver' }
      expect(maggie[:campusSolutionsId]).to eq '24363318'
      expect(maggie[:uid]).to eq maggie_uid
      expect(maggie[:privileges]).to eq({ financial: true, viewEnrollments: false, viewGrades: false, phone: true })
    end
  end
end
