describe CampusSolutions::ResidencyMessage do

  shared_examples 'a proxy that gets data' do
    let(:message_nbr) {'2005'}
    let(:params) { {messageNbr: message_nbr} }
    let(:proxy) { CampusSolutions::ResidencyMessage.new(fake: true, params: params) }
    subject{
      proxy.get
    }

    it_should_behave_like 'a simple proxy that returns errors'
    it_behaves_like 'a proxy that got data successfully'
    it 'returns data with the expected structure' do
      message = subject[:feed][:root][:getMessageCatDefn]
      expect(message[:messageSetNbr]).to eq "28001"
      expect(message[:messageNbr]).to eq message_nbr
      expect(message[:messageText]).to be
      expect(message[:descrlong]).to be
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
