describe Notifications::SisExpiryProcessor do
  shared_context 'expecting no expiry notifications' do
    before do
      Notifications::SisExpiryProcessor::EXPIRY_BY_TOPIC.each_value do |expiry_class|
        expect(expiry_class).not_to receive(:expire)
      end
    end
  end

  shared_examples 'an event not accepted' do
    include_context 'expecting no expiry notifications'
    it 'should not accept event' do
      expect(subject.process(event, Time.now.to_datetime)).to eq false
    end
  end

  context 'when an event is malformed' do
    let(:event) { {'thoroughgoing' => 'persiflage'} }
    it_should_behave_like 'an event not accepted'
  end

  context 'when an event is well-formed' do
    let(:event) do
      {
        'payload' => {
          'student' => {
            'StudentId' => campus_solutions_id
          }
        },
        'timestamp' => '2013-06-01T07:15:01.000-07:00',
        'topic' => topic
      }
    end
    let(:campus_solutions_id) { 17154428 }

    context 'when topic is unrecognized' do
      let(:topic) { 'persiflage' }
      it_should_behave_like 'an event not accepted'
    end

    context 'when topic is recognized' do
      let(:topic) { 'sis:student:enrollment' }

      context 'when UID cannot be looked up' do
        before { allow_any_instance_of(CalnetCrosswalk::ByCsId).to receive(:lookup_ldap_uid).and_return nil  }
        include_context 'expecting no expiry notifications'
        it 'should log the lookup failure' do
          expect(Rails.logger).to receive(:error).with /No UID found for Campus Solutions ID/
          subject.process(event, Time.now.to_datetime)
        end
      end

      context 'successful UID lookup' do
        let(:uid) { '61889' }
        before { allow_any_instance_of(CalnetCrosswalk::ByCsId).to receive(:lookup_ldap_uid).and_return uid  }
        it 'expires the specified class and UID only' do
          Notifications::SisExpiryProcessor::EXPIRY_BY_TOPIC.each_value do |expiry_class|
            if expiry_class == CampusSolutions::EnrollmentTermExpiry
              expect(expiry_class).to receive(:expire).with(uid).once
            else
              expect(expiry_class).not_to receive(:expire)
            end
          end
          subject.process(event, Time.now.to_datetime)
        end
      end
    end
  end
end
