describe CampusSolutions::EnrollmentVerificationMessages do

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::EnrollmentVerificationMessages.new(fake: true) }
    subject { proxy.get }

    it_should_behave_like 'a simple proxy that returns errors'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:root][:getMessageCatDefn]).to be
      expect(subject[:feed][:root][:getMessageCatDefn][0][:messageNbr]).to eq "1"
      expect(subject[:feed][:root][:getMessageCatDefn][1][:messageNbr]).to eq "2"
    end
  end

end
