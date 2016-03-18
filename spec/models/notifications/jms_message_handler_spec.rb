describe Notifications::JmsMessageHandler do
  let(:reg_status_processor) { double('Notifications::RegStatusEventProcessor', process: true) }
  let(:final_grades_processor) { double('Notifications::FinalGradesEventProcessor', process: true) }
  let(:sis_expiry_processor) { double('Notification::SisExpiryProcessor', process: true) }
  let(:handler) { Notifications::JmsMessageHandler.new [reg_status_processor, final_grades_processor, sis_expiry_processor] }

  shared_examples 'a handler doing nothing' do
    it 'should pass nothing on to processors' do
      expect(reg_status_processor).not_to receive :process
      expect(final_grades_processor).not_to receive :process
      expect(sis_expiry_processor).not_to receive :process
      handler.handle message
    end
  end

  context 'empty message' do
    let(:message) { {} }
    it_should_behave_like 'a handler doing nothing'
  end
  context 'malformed JSON' do
    let(:message) { {text: 'pure lunacy'} }
    it_should_behave_like 'a handler doing nothing'
  end

  context 'parseable messages' do
    let(:messages) do
      File.read("#{Rails.root}/fixtures/jms_recordings/ist_jms.txt").split("\n\n").map { |yml| YAML::load yml }
    end
    it 'should pass a series of messages to all processors' do
      expect(reg_status_processor).to receive(:process).exactly(5).times
      expect(final_grades_processor).to receive(:process).exactly(5).times
      expect(sis_expiry_processor).to receive(:process).exactly(5).times
      messages.each { |msg| handler.handle msg }
    end
  end
end
