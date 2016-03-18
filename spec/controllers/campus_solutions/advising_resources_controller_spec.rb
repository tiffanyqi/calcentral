describe CampusSolutions::AdvisingResourcesController do
  let(:user_id) { '12349' }
  let(:feed) { :get }
  it_behaves_like 'an unauthenticated user'

  context 'authenticated user' do
    before do
      session['user_id'] = user_id
      allow(HubEdos::UserAttributes).to receive(:new).with(user_id: user_id).and_return double(get: {roles: user_roles})
    end

    context 'no advisor privileges' do
      let(:user_roles) { {staff: true, student: true} }
      it 'returns forbidden' do
        get feed
        expect(response.status).to eq 403
      end
    end

    context 'advisor privileges' do
      let(:user_roles) { {staff: true, advisor: true} }
      let(:feed_key) { 'ucAdvisingResources' }
      it_behaves_like 'a successful feed'
      it 'includes specific mock data' do
        get feed
        json = JSON.parse(response.body)
        expect(json['feed']['ucAdvisingResources']['ucAdvisingLinks']['ucAdviseeStudentCenter']['url'].strip).to eq(
          'https://bcs-web-dev-03.is.berkeley.edu:8443/psc/bcsdev/EMPLOYEE/HRMS/c/SSR_ADVISEE_OVRD.SSS_STUDENT_CENTER.GBL?')
      end
    end
  end
end
