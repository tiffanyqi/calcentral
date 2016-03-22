describe CampusSolutions::LanguageCode do

  shared_examples 'a proxy that gets data' do
    let(:proxy) { CampusSolutions::LanguageCode.new fake: fake_proxy }
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that properly observes the profile feature flag'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      languages = subject[:feed][:accomplishments].map { |language| language[:descr] }
      expected_sample = %w(Armenian Hindi/Urdu Yiddish)
      expect(expected_sample - languages).to be_empty
    end
  end

  context 'mock proxy' do
    let(:fake_proxy) { true }
    it_should_behave_like 'a proxy that gets data'
  end

  context 'real proxy', testext: true do
    let(:fake_proxy) { false }
    it_should_behave_like 'a proxy that gets data'
  end

end
