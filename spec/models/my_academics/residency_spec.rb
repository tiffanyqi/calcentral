require 'spec_helper'

describe MyAcademics::Residency do
  let(:feed) { described_class.new(uid).get_feed }

  let(:uid) { '61889' }
  # As deciphered by ResidencyMessageCode
  let(:message_nbr) { '2005' }
  let(:fake_demographics_proxy) { HubEdos::Demographics.new(fake: true, user_id: uid) }
  let(:fake_residency_message_proxy) { CampusSolutions::ResidencyMessage.new(fake: true, messageNbr: message_nbr) }

  context 'fake data' do
    before do
      allow(HubEdos::Demographics).to receive(:new).with(user_id: uid).and_return fake_demographics_proxy
      allow(CampusSolutions::ResidencyMessage).to receive(:new).with({messageNbr: message_nbr}).and_return fake_residency_message_proxy
    end
    it 'contains the expected data' do
      residency = feed[:residency]
      expect(residency[:official][:code]).to eq 'NON'
      expect(residency[:fromTerm][:label]).to eq 'Summer 2014'
      expect(residency[:message][:code]).to eq '2005'
      expect(residency[:message][:label]).to eq 'Submitted & Completed & Non-Resident & Excs'
      expect(residency[:message][:description]).to be_present
    end
  end

end
