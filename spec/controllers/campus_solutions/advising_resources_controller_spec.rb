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
      let(:user_roles) { { staff: true, student: true } }
      it 'returns forbidden' do
        get feed
        expect(response.status).to eq 403
      end
    end

    context 'advisor privileges' do
      let(:user_roles) { { staff: true, advisor: true } }
      let(:feed_key) { 'ucAdvisingResources' }

      shared_examples 'a feed with advising resources' do
        it 'contains advising links' do
          get feed
          json = JSON.parse response.body
          expect(resources = json['feed']['ucAdvisingResources']).to_not be_nil
          expect(link = resources['ucAdvisingLinks'][key]).to_not be_nil
          expect(link['isCsLink']).to be true
          expect(link['name']).to eq expected_name
        end
      end

      context 'links from the CS API' do
        let(:key) { 'ucAdviseeStudentCenter' }
        let(:expected_name) { 'Advisee Student Center' }

        it_behaves_like 'a feed with advising resources'
      end

      context 'links from YAML settings' do
        let(:key) { 'multiYearAcademicPlannerGeneric' }
        let(:expected_name) { 'Multi-Year Planner' }

        it_behaves_like 'a feed with advising resources'
      end
    end
  end

end
