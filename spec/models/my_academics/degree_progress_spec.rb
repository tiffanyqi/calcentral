describe MyAcademics::DegreeProgress do

  let(:model) { MyAcademics::DegreeProgress.new(user_id) }
  let(:user_id) { '12345' }

  describe '#get_feed_internal' do
    subject { model.get_feed_internal }

    it_behaves_like 'a proxy that properly observes the degree progress feature flag'

    it 'returns data with the expected structure' do
      expect(subject[:feed][:degreeProgress]).to be
      expect(subject[:feed][:degreeProgress].first[:acadCareer]).to be
      expect(subject[:feed][:degreeProgress].first[:acadPlanCode]).to be
      expect(subject[:feed][:degreeProgress].first[:acadPlanDescr]).to be
      expect(subject[:feed][:degreeProgress].first[:acadProgCode]).to be
      expect(subject[:feed][:degreeProgress].first[:acadProgDescr]).to be
      expect(subject[:feed][:degreeProgress].first[:requirements]).to be
      expect(subject[:feed][:links]).to be
      expect(subject[:feed][:links][:advancementFormSubmit]).to be
      expect(subject[:feed][:links][:advancementFormView]).to be
    end

    it 'filters out any LAW career programs that are not LACAD' do
      expect(subject[:feed][:degreeProgress].length).to eql(3)
    end

    it 'filters out requirements that we don\'t want to display' do
      expect(subject[:feed][:degreeProgress][0][:requirements].length).to eql(1)
    end

    it 'merges two Advancement to Candidacy milestones if neither one is complete' do
      expect(subject[:feed][:degreeProgress][1][:requirements].length).to eql(1)
    end

    it 'replaces milestone code and status code with descriptive names' do
      expect(subject[:feed][:degreeProgress][1][:requirements][0][:name]).to eql('Advancement to Candidacy Plan I or Plan II')
      expect(subject[:feed][:degreeProgress][1][:requirements][0][:status]).to be nil
      expect(subject[:feed][:degreeProgress][2][:requirements][0][:name]).to eql('Approval for Qualifying Exam')
      expect(subject[:feed][:degreeProgress][2][:requirements][0][:status]).to eql('Completed')
    end
  end
end
