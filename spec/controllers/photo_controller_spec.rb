describe PhotoController do
  let(:make_request) { get :my_photo }
  it_should_behave_like 'an authenticated endpoint'

  context 'when a user is authenticated' do
    before do
      session['user_id'] = random_id
      allow_any_instance_of(Cal1card::Photo).to receive(:get_feed).and_return(test_photo_object)
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
      let(:test_photo_object) { {} }
      it_should_behave_like 'a controller with no photo'
    end

    context 'when user has photo' do
      let(:test_photo_object) { {photo: 'photo_binary_content'} }
      it_should_behave_like 'a controller with a photo'
      context 'delegate view' do
        before do
          session[SessionKey.original_delegate_user_id] = random_id
          allow(Settings.features).to receive(:cs_delegated_access).and_return true
        end
        it 'returns an empty body' do
          make_request
          expect(response.body).to eq ' '
        end
      end
    end
  end
end
