describe CampusSolutions::FerpaDeeplink do

  shared_examples 'a proxy that gets data' do
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:ucSrFerpa][:ferpaDeeplink][:name]).to eq 'Manage FERPA Restrictions'
      expect(subject[:feed][:ucSrFerpa][:ferpaDeeplink][:isCsLink]).to be true
      expect(subject[:feed][:ucSrFerpa][:ferpaDeeplink][:url]).to include "/UC_CC_STDNT_FERPA.v1/FERPA/GET?EMPLID="
    end
  end

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::FerpaDeeplink.new(fake: true, user_id: '10000039') }
    it_should_behave_like 'a proxy that gets data'
  end

  context 'real proxy', testext: true do
    let(:proxy) { CampusSolutions::FerpaDeeplink.new(fake: false, user_id: '10000039') }
    it_should_behave_like 'a proxy that gets data'
  end

end
