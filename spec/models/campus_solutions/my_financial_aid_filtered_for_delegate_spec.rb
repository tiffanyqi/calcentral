describe CampusSolutions::MyFinancialAidFilteredForDelegate do

  subject { CampusSolutions::MyFinancialAidFilteredForDelegate.from_session state }
  let(:state) { { 'fake' => true, 'user_id' => random_id } }

  context 'mock proxy' do
    context 'no aid year provided' do
      it 'should return empty' do
        expect(subject.get_feed).to be_empty
      end
    end
    context 'aid year provided' do
      before { subject.aid_year = '2016' }
      context 'no delegate session' do
        it 'should deny access' do
          expect{
            subject.get_feed
          }.to raise_exception /Only delegate users have access/
        end
      end
      context 'delegate session' do
        let(:state) { { 'fake' => true, 'user_id' => random_id, 'original_delegate_user_id' => random_id } }
        it 'should filter out \'Expected Family Contribution\' and similar' do
          feed = subject.get_feed
          expect(feed[:filteredForDelegate]).to be true
          json = feed.to_json
          expect(json).to include 'SHIP Health Insurance', 'Student Standing', 'Estimated Cost of Attendance'
          expect(json).to_not include 'EFC', 'Family', 'Parent'
        end
      end
    end
  end
end
