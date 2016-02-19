describe PhotoController do
  let(:make_request) { get :my_photo }
  it_should_behave_like 'an authenticated endpoint'

  context 'when a user is authenticated' do
    before do
      session['user_id'] = random_id
      allow(CampusOracle::Queries).to receive(:get_photo).and_return(test_photo_object)
    end

    shared_examples 'a controller with no photo' do
      it 'returns an empty body' do
        make_request
        expect(response.status).to eq 200
        expect(response.body).to eq ' '
      end
    end

    shared_examples 'a controller with a photo' do
      it 'renders raw image' do
        make_request
        expect(response.status).to eq 200
        expect(response.body).to eq 'photo_binary_content'
      end
    end

    context 'when user has no photo' do
      let(:test_photo_object) { nil }
      it_should_behave_like 'a controller with no photo'
    end

    context 'when user has photo' do
      let(:test_photo_object) { {'photo' => 'photo_binary_content'} }
      it_should_behave_like 'a controller with a photo'
      context 'delegate view' do
        before do
          allow_any_instance_of(AuthenticationState).to receive(:authenticated_as_delegate?).and_return true
          allow_any_instance_of(AuthenticationState).to receive(:delegate_permissions).and_return({ privileges: { view_grades: true } })
          allow(Settings.features).to receive(:cs_delegated_access).and_return true
        end
        it_should_behave_like 'a controller with no photo'
      end
    end
  end
end
