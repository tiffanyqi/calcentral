describe StudentSuccess::TermGpa do

  context 'a mock proxy' do
    before do
      allow(Settings.campus_solutions_proxy).to receive(:fake).and_return true
    end
    it 'correctly parses the feed' do
      result = StudentSuccess::TermGpa.new(user_id: 61889).merge
      expect(result).to be_an Array
      expect(result[0][:termName]).to eq 'Fall 2012'
    end
  end

end
