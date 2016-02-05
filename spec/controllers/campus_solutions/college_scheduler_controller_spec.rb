describe CampusSolutions::CollegeSchedulerController do
  let(:options) { {term_id: '2167', acad_career: 'UGRD'} }
  let(:scheduler_url) { 'HTTPS://BERKELEYDEV.COLLEGESCHEDULER.COM/INDEX.ASPX?TICKET=C0EC99DE53574F78906FB21169B2045C_SSO' }

  context 'no authenticated user' do
    it 'returns 401' do
      get :get, options
      expect(response.status).to eq 401
      expect(response.body.strip).to eq ''
    end
  end

  context 'authenticated user' do
    let(:user_id) { '12349' }
    before { session['user_id'] = user_id }

    context 'feature flag off' do
      before { allow(Settings.features).to receive(:cs_enrollment_card).and_return false }
      it 'should redirect to 404' do
        get :get, options
        expect(response).to redirect_to '/404'
      end
    end

    context 'feature flag on' do
      before { allow(Settings.features).to receive(:cs_enrollment_card).and_return true }
      it 'should redirect to a College Scheduler URL' do
        get :get, options
        expect(response).to redirect_to scheduler_url
      end

      context 'when College Scheduler URL not found' do
        before { allow_any_instance_of(CampusSolutions::CollegeSchedulerUrl).to receive(:get_college_scheduler_url).and_return(nil) }
        it 'should redirect to 404' do
          get :get, options
          expect(response).to redirect_to '/404'
        end
      end
    end
  end
end
