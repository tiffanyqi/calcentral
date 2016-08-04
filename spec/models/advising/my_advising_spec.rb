describe Advising::MyAdvising do
  let(:uid) { random_id }
  subject { described_class.new(uid).get_feed_internal }

  context 'fake proxies' do
    let(:fake_proxies) do
      proxies = {}
      Advising::MyAdvising::FEED_COMPONENTS.each_value do |proxy_class|
        fake_proxy = proxy_class.new(user_id: uid, fake: true)
        proxies[proxy_class] = fake_proxy
        allow(proxy_class).to receive(:new).and_return fake_proxy
      end
      proxies
    end

    context 'well-behaved proxies' do
      it 'should return successful status code' do
        expect(subject[:statusCode]).to eq 200
      end
      it 'should include expected action items' do
        expect(subject[:feed][:advisorActionItems][:ucAaActionItems][:actionItems]).to have(12).items
        expect(subject[:feed][:advisorActionItems][:ucAaActionItems][:actionItems].first).to include({
          actionItemAssignedDate: '2016-07-22',
          actionItemDescription: 'Testing 123',
          actionItemDueDate: '2016-07-25',
          actionItemStatus: 'Incomplete',
          actionItemTitle: 'Action Item test',
          actionItemView: 'Complete'
        })
      end
      it 'should include expected advising appointments' do
        expect(subject[:feed][:advisorAppointments][:ucAaAdvisingAppts][:advisingAppts]).to have(23).items
        expect(subject[:feed][:advisorAppointments][:ucAaAdvisingAppts][:advisingAppts].first).to include({
          apptAdvisorId: '3030312345',
          apptAdvisorName: 'Jane Smith',
          apptCategory: 'Academic Advising',
          apptDate: '2016-07-25',
          apptDuration: '30',
          apptReason: 'Add',
          apptScheduledTime: '08.00.00.000000',
          apptStatus: 'CANCEL',
          apptType: 'Drop-in'
        })
      end
      it 'should include expected advisor relationships' do
        expect(subject[:feed][:advisorRelationships][:ucAaStudentAdvisor][:studentAdvisor]).to have(1).items
        expect(subject[:feed][:advisorRelationships][:ucAaStudentAdvisor][:studentAdvisor].first).to include({
          assignedAdvisorEmail: 'janed@example.com',
          assignedAdvisorName: 'Jane Doe',
          assignedAdvisorProgram: 'Undergrad Chemistry',
          assignedAdvisorType: 'College Advisor'
        })
      end
    end

    shared_examples 'a good and proper error report' do
      it 'reports error' do
        expect(Rails.logger).to receive(:error).with /Got errors in merged MyAdvising feed/
        expect(subject[:statusCode]).to eq 500
        expect(subject[:errored]).to eq true
      end
    end

    context 'proxy returns an error' do
      before do
        allow(fake_proxies[CampusSolutions::AdvisorStudentAppointmentCalendar]).to receive(:get).and_return(errored: true)
      end
      it_should_behave_like 'a good and proper error report'
    end

    context 'proxy fails to look up student ID' do
      before do
        allow(fake_proxies[CampusSolutions::AdvisorStudentActionItems]).to receive(:get).and_return(noStudentId: true)
      end
      it_should_behave_like 'a good and proper error report'
    end
  end
end
