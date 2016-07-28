describe CampusSolutions::AdvisorStudentAppointmentCalendar do
  let(:user_id) { '12345' }
  before do
    allow(CalnetCrosswalk::ByUid).to receive(:new).with(user_id: user_id).and_return(
      double(lookup_campus_solutions_id: user_id))
  end

  shared_examples 'a proxy that gets data' do
    subject { proxy.get }
    it_should_behave_like 'a simple proxy that returns errors'
    it 'returns data with the expected structure' do
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts]).to be
    end
  end

  context 'mock proxy' do
    let(:proxy) { CampusSolutions::AdvisorStudentAppointmentCalendar.new(fake: true, user_id: user_id) }
    it_should_behave_like 'a proxy that gets data'
    subject { proxy.get }
    it 'should get specific mock data' do
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptDate]).to eq '2016-07-25'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptScheduledTime]).to eq '08.00.00.000000'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptDuration]).to eq '30'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptAdvisorId]).to eq '3030312345'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptAdvisorName]).to eq 'Jane Smith'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptStatus]).to eq 'CANCEL'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptType]).to eq 'Drop-in'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptTypeDetail]).to eq nil
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptCategory]).to eq 'Academic Advising'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptReason]).to eq 'Add'
      expect(subject[:feed][:ucAaAdvisingAppts][:advisingAppts][0][:apptReasonAddl]).to eq nil
    end
  end

  context 'real proxy', testext: true, :ignore => true do
    let(:proxy) { CampusSolutions::AdvisorStudentAppointmentCalendar.new(fake: false, user_id: user_id) }
    it_should_behave_like 'a proxy that gets data'
  end
end
