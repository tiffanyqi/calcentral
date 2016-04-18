describe CampusSolutions::SLRDeeplink do

  shared_examples 'a proxy that gets data' do
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:root][:ucSrSlrResources][:ucSlrLinks][:ucSlrLink][:isCsLink]).to eq(true)
      expect(subject[:feed][:root][:ucSrSlrResources][:ucSlrLinks][:ucSlrLink][:name]).to eq("SLR_LINK")
      expect(subject[:feed][:root][:ucSrSlrResources][:ucSlrLinks][:ucSlrLink][:url]).to eq("https://bcs-web-dev-03.is.berkeley.edu:8443/psc/bcsdev/EMPLOYEE/HRMS/c/UC_SR_SLR.UC_SLR_STDNT.GBL")
    end
  end

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::SLRDeeplink.new(fake: true) }
    it_should_behave_like 'a proxy that gets data'
  end

  context 'real proxy', testext: true do
    let(:proxy) { CampusSolutions::SLRDeeplink.new(fake: false) }
    it_should_behave_like 'a proxy that gets data'
  end

end
