describe MyRegistrations::MyRegistrations do
  before(:each) do
    @model = MyRegistrations::MyRegistrations.new(user_id: '61889')
    allow(@model).to receive(:get_registrations).and_return ({
      "affiliations" => "GRAD",
      "registrations" => [
        {
         "term" => {
           "id" => 2156,
           "name" => "2015 Fall",
           "academicYear" => "2016"
         }
       },
       {
         "term" => {
           "id" => 2159,
           "name" => "2016 Spring",
           "academicYear" => "2016"
         }
       },
       {
         "term" => {
           "id" => 2162,
           "name" => "2016 Fall",
           "academicYear" => "2017"
         }
       },
       {
         "term" => {
           "id" => 2165,
           "name" => "2017 Spring",
           "academicYear" => "2017"
         }
       },
       {
         "term" => {
           "id" => 2168,
           "name" => "2017 Summer",
           "academicYear" => "2017"
         }
       },
       {
       "term" => {
         "id" => 2171,
         "name" => "2017 Fall",
         "academicYear" => "2018"
       }
     }
    ]})
  end

  context 'fully populated berkeley terms' do
    before do
      allow(@model).to receive(:get_terms).and_return ({
        :current => 2162,
        :running => 2162,
        :sis_current_term => 2165,
        :next => 2168,
        :future => 2171,
        :previous => 2159,
        :grading_in_progress => 2159
      })
    end
    it 'returns all matched terms' do
      matched_terms = @model.get_feed_internal
      expect(matched_terms[:registrations][:current][0]["term"]["id"]).to eq 2162
      expect(matched_terms[:registrations][:running][0]["term"]["id"]).to eq 2162
      expect(matched_terms[:registrations][:sis_current_term][0]["term"]["id"]).to eq 2165
      expect(matched_terms[:registrations][:next][0]["term"]["id"]).to eq 2168
      expect(matched_terms[:registrations][:future][0]["term"]["id"]).to eq 2171
      expect(matched_terms[:registrations][:previous][0]["term"]["id"]).to eq 2159
      expect(matched_terms[:registrations][:grading_in_progress][0]["term"]["id"]).to eq 2159
    end
  end

  context 'some populated berkeley terms' do
    before do
      allow(@model).to receive(:get_terms).and_return ({
        :current => [],
        :running => [],
        :sis_current_term => [],
        :next => 2168,
        :future => 2171,
        :previous => [],
        :grading_in_progress => 2159
      })
    end
    it 'returns all matched terms' do
      matched_terms = @model.get_feed_internal
      matched_terms[:registrations][:current].should have(0).items
      matched_terms[:registrations][:running].should have(0).items
      matched_terms[:registrations][:sis_current_term].should have(0).items
      expect(matched_terms[:registrations][:next][0]["term"]["id"]).to eq 2168
      expect(matched_terms[:registrations][:future][0]["term"]["id"]).to eq 2171
      matched_terms[:registrations][:previous].should have(0).items
      expect(matched_terms[:registrations][:grading_in_progress][0]["term"]["id"]).to eq 2159
    end
  end

  context 'no populated berkeley terms' do
    before do
      allow(@model).to receive(:get_terms).and_return ({
        :current => [],
        :running => [],
        :sis_current_term => [],
        :next => [],
        :future => [],
        :previous => [],
        :grading_in_progress => []
      })
    end
    it 'returns no matched terms' do
      matched_terms = @model.get_feed_internal
      matched_terms[:registrations][:current].should have(0).items
      matched_terms[:registrations][:running].should have(0).items
      matched_terms[:registrations][:sis_current_term].should have(0).items
      matched_terms[:registrations][:next].should have(0).items
      matched_terms[:registrations][:future].should have(0).items
      matched_terms[:registrations][:previous].should have(0).items
      matched_terms[:registrations][:grading_in_progress].should have(0).items
    end
  end

  context 'populated berkeley terms with no matches' do
    before do
      allow(@model).to receive(:get_terms).and_return ({
        :current => 1240,
        :running => 1240,
        :sis_current_term => 1243,
        :next => 1243,
        :future => 1246,
        :previous => 1238,
        :grading_in_progress => 1238
      })
    end
    it 'returns no matched terms' do
      matched_terms = @model.get_feed_internal
      matched_terms[:registrations][:current].should have(0).items
      matched_terms[:registrations][:running].should have(0).items
      matched_terms[:registrations][:sis_current_term].should have(0).items
      matched_terms[:registrations][:next].should have(0).items
      matched_terms[:registrations][:future].should have(0).items
      matched_terms[:registrations][:previous].should have(0).items
      matched_terms[:registrations][:grading_in_progress].should have(0).items
    end
  end

end
