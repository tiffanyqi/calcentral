describe CalGroups::MemberAdd do
  let(:stem_name) { 'edu:berkeley:app:bcourses' }
  let(:group_name) { "site-#{random_id}" }
  let(:member_id) { random_id }
  let(:proxy) { described_class.new(stem_name: stem_name, group_name: group_name, member_id: member_id, fake: fake) }
  let(:result) { proxy.add[:response] }

  after(:each) { WebMock.reset! }

  context 'fake data feed' do
    let(:fake) { true }

    shared_examples 'error response' do
      it 'reports an error' do
        expect(result[:statusCode]).to eq 503
      end
    end

    shared_examples 'verbose response' do
      it 'includes member and group data' do
        %w(displayExtension displayName extension idIndex name typeOfGroup uuid).each do |key|
          expect(result[:group][key]).to be_present
        end
        %w(id name resultCode sourceId success).each do |key|
          expect(result[:member][key]).to be_present
        end
      end
    end

    context 'when member is successfully added' do
      it 'affirms addition' do
        expect(result[:added]).to eq true
      end
      include_examples 'verbose response'
    end

    context 'when member is already in group' do
      before do
        proxy.override_json do |json|
          json['WsAddMemberLiteResult']['resultMetadata']['resultCode'] = 'SUCCESS_ALREADY_EXISTED'
        end
      end
      it 'denies addition' do
        expect(result[:added]).to eq false
      end
      include_examples 'verbose response'
    end

    context 'when group does not exist' do
      before do
        proxy.set_response({
          status: 404,
          body: '{"WsAddMemberLiteResult":{"resultMetadata":{"resultCode":"GROUP_NOT_FOUND","success":"F"}}}'
        })
      end
      include_examples 'error response'
    end

    context 'when member does not exist' do
      before do
        proxy.set_response({
          status: 404,
          body: '{"WsAddMemberLiteResult":{"resultMetadata":{"resultCode":"EXCEPTION","resultMessage":"SUBJECT_NOT_FOUND",success":"F"}}}'
        })
      end
      include_examples 'error response'
    end

    context 'on unspecified failure' do
      before do
        proxy.override_json do |json|
          json['WsAddMemberLiteResult']['resultMetadata']['success'] = 'F'
        end
      end
      include_examples 'error response'
    end
  end

  context 'real data feed' do
    let(:fake) { false }
    it_behaves_like 'a proxy logging errors' do
      subject { result }
    end
  end
end