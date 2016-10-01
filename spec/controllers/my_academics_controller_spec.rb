describe MyAcademicsController do
  let(:feed_key) { 'feed' }
  let(:models) do
    {
      delegate: MyAcademics::FilteredForDelegate,
      advisor: MyAcademics::FilteredForAdvisor,
      merged: MyAcademics::Merged,
      residency: MyAcademics::Residency
    }
  end

  before do
    models.each_value do |model|
      allow(model).to receive(:from_session).and_return double get_feed_as_json: { feed: model.name }
    end
  end

  describe '#get_feed' do
    let(:make_request) { get :get_feed }

    it_behaves_like 'a user authenticated api endpoint'

    context 'when authenticated user exists' do
      let(:uid) { '12345' }

      subject { make_request }

      context 'normal user session' do
        it 'should return a merged feed' do
          session['user_id'] = uid
          json = JSON.parse subject.body
          expect(json[feed_key]).to eq models[:merged].name
        end
      end

      context 'delegated access' do
        let(:campus_solutions_id) { '98765' }
        let(:privileges) {{ viewEnrollments: true }}
        include_context 'delegated access'

        it 'should return a delegate-filtered feed' do
          json = JSON.parse subject.body
          expect(json[feed_key]).to eq models[:delegate].name
        end
      end

      context 'advisor view-as' do
        include_context 'advisor view-as'
        it 'should return an advisor-filtered feed' do
          json = JSON.parse subject.body
          expect(json[feed_key]).to eq models[:advisor].name
        end
      end
    end
  end

  describe '#residency' do
    let(:make_request) { get :residency }

    it_behaves_like 'a user authenticated api endpoint'

    context 'when authenticated user exists' do
      let(:uid) { '12345' }

      subject { make_request }

      context 'normal user session' do
        it 'should return a populated feed' do
          session['user_id'] = uid
          json = JSON.parse subject.body
          expect(json[feed_key]).to eq models[:residency].name
        end
      end

      context 'delegated access' do
        let(:campus_solutions_id) { '98765' }
        let(:privileges) {{ viewEnrollments: true }}
        include_context 'delegated access'

        it 'should return an empty feed' do
          json = JSON.parse subject.body
          expect(json.length).to eq 0
        end
      end
    end
  end
end
