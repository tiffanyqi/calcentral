describe CampusSolutions::CollegeSchedulerUrl do

  let(:options) { {user_id: '12349', term_id: '2168', acad_career: 'UGRD'} }

  shared_examples 'a proxy that gets data' do
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that properly observes the enrollment card flag'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:scheduleplannerssolink][:url]).to be
    end
  end

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::CollegeSchedulerUrl.new options }
    subject { proxy.get }
    it_should_behave_like 'a proxy that gets data'
    it 'should get specific mock data' do
      expect(proxy.get_college_scheduler_url).to eq 'HTTPS://BERKELEYDEV.COLLEGESCHEDULER.COM/INDEX.ASPX?TICKET=C0EC99DE53574F78906FB21169B2045C_SSO'
    end
  end

end
