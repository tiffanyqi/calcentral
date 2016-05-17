describe BootstrapController do
  let(:user_id) { random_id }

  context 'when not authenticated' do
    it 'should not make a warmup request' do
      expect(LiveUpdatesWarmer).to receive(:warmup_request).never
      get :index
    end
  end

  context 'when authenticated' do
    before do
      session['user_id'] = user_id
    end
    it 'makes a warmup request' do
      expect(LiveUpdatesWarmer).to receive(:warmup_request).with(user_id).once
      get :index
    end
  end

  context 'when previously authenticated by LTI' do
    before do
      session['user_id'] = user_id
      session['lti_authenticated_only'] = true
    end
    it 'should force campus authentication' do
      get :index
      hostname = request.env['HTTP_HOST']
      expect(response).to redirect_to '/auth/cas'
    end
  end

  describe 'reauthentication' do
    let(:original_user_id) {nil}
    before do
      expect(Settings.features).to receive(:reauthentication).and_return(true)
      session['user_id'] = user_id
      session[SessionKey.original_user_id] = original_user_id
    end
    context 'when viewing as' do
      let(:original_user_id) {random_id}
      context 'when not already reauthenticated' do
        it 'should redirect to reauthenticate' do
          get :index
          hostname = request.env['HTTP_HOST']
          expect(response).to redirect_to "/auth/cas?renew=true&url=http://#{hostname}/"
        end
      end
      context 'when already reauthenticated' do
        before do
          allow(controller).to receive(:cookies).and_return({reauthenticated: true})
        end
        it 'should not redirect' do
          get :index
          expect(response).not_to redirect_to('/auth/cas?renew=true&url=/')
        end
      end
    end
    context 'when not viewing as' do
      it 'should not redirect' do
        get :index
        expect(response).not_to redirect_to('/auth/cas?renew=true&url=/')
      end
    end
  end

end
