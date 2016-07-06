describe MyAcademics::Merged do
  let(:provider_classes) do
    [
      MyAcademics::CollegeAndLevel,
      MyAcademics::TransitionTerm,
      MyAcademics::GpaUnits,
      MyAcademics::Requirements,
      MyAcademics::Regblocks,
      MyAcademics::Semesters,
      MyAcademics::Teaching,
      MyAcademics::Exams,
      MyAcademics::CanvasSites
    ]
  end

  let(:uid) { '61889' }

  let(:oski_providers) do
    provider_classes.each_with_object({}) do |provider_class, providers|
      providers[provider_class] = provider_class.new uid
    end
  end

  def set_mock_merge(providers)
    providers.each_value do |provider|
      expect(provider).to receive(:merge) do |feed|
        feed[provider.class.to_s] = true
      end
    end
  end

  before do
    oski_providers.each do |provider_class, oski_provider|
      allow(provider_class).to receive(:new).and_return oski_provider
    end
  end

  context 'when providers are well behaved' do
    before { set_mock_merge oski_providers }

    it 'should merge all providers into hash' do
      feed = described_class.new(uid).get_feed
      provider_classes.each { |provider_class| expect(feed[provider_class.to_s]).to eq true }
      expect(feed[:errors]).to be_blank
    end
  end

  context 'when a provider misbehaves' do
    before do
      bad_provider = oski_providers.delete MyAcademics::Exams
      expect(bad_provider).to receive(:merge).and_raise NoMethodError
      set_mock_merge oski_providers
    end

    it 'should merge other providers and report error' do
      expect(Rails.logger).to receive(:error).with /Failed to merge MyAcademics::Exams for UID #{uid}: NoMethodError/
      feed = described_class.new(uid).get_feed
      well_behaved_classes = provider_classes - [MyAcademics::Exams]
      well_behaved_classes.each { |well_behaved_class| expect(feed[well_behaved_class.to_s]).to eq true }
      expect(feed).not_to include 'MyAcademics::Exams'
      expect(feed[:errors]).to eq ['MyAcademics::Exams']
    end
  end

  describe '#filter_course_sites' do
    let(:full_feed) {HashConverter.symbolize JSON.parse(File.read(Rails.root.join('public/dummy/json/academics.json')))}
    it 'includes bCourses sites in a full feed' do
      expect(full_feed[:semesters][1][:classes][2][:class_sites].index {|c| c[:emitter] == 'bCourses'}).to_not be_nil
      expect(full_feed[:teachingSemesters][0][:classes][0][:class_sites].index {|c| c[:emitter] == 'bCourses'}).to_not be_nil
      expect(full_feed[:otherSiteMemberships][0][:sites].index {|c| c[:emitter] == 'bCourses'}).to_not be_nil
    end
    it 'removes course sites from the full feed' do
      feed = described_class.new(uid).filter_course_sites full_feed
      expect(feed[:semesters][1][:classes][2][:class_sites]).to be_blank
      expect(feed[:teachingSemesters][0][:classes][0][:class_sites]).to be_blank
      expect(feed[:otherSiteMemberships]).to be_blank
    end
  end
end
