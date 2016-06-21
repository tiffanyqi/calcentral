describe CampusSolutions::MyHigherOneUrl do
  let(:user_id) { random_id }
  before {
    expect(CampusSolutions::HigherOneUrl).to receive(:new).and_return(model = double)
    expect(model).to receive(:build_url).and_return url
  }

  context '#get_higher_one_url' do
    let(:proxy) { CampusSolutions::MyHigherOneUrl.from_session('user_id' => random_id) }
    subject { proxy.get_higher_one_url}
    context 'nil response from Campus Solutions' do
      let(:url) { nil }
      it 'should return feed after update' do
        expect(subject).to be nil
      end
    end
    context 'non-empty url from Campus Solutions' do
      let(:url) { ' http://cash.money.com    ' }
      it 'should return feed after update' do
        expect(subject).to eq 'http://cash.money.com'
      end
    end
  end

end
