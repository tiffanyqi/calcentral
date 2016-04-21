describe EdoOracle::SubjectAreas do

  subject { described_class.fetch }
  before do
    allow(EdoOracle::Queries).to receive(:get_subject_areas).and_return subject_areas.map { |area| {'subjectarea' => area} }
  end

  context 'a variety of subject areas' do
    let(:subject_areas) { ['ARABIC', 'COM LIT', 'ENE,RES', 'ENGLISH', 'L & S', 'XL&S'] }
    it 'provides decompressions' do
      expect(subject.decompress 'COMLIT').to eq 'COM LIT'
      expect(subject.decompress 'ENERES').to eq 'ENE,RES'
      expect(subject.decompress 'LS').to eq 'L & S'
      expect(subject.decompress 'XLS').to eq 'XL&S'
    end
    it 'allows no-op decompressions to pass through' do
      expect(subject.decompress 'COM LIT').to eq 'COM LIT'
      expect(subject.decompress 'ENGLISH').to eq 'ENGLISH'
      expect(subject.decompress 'L & S').to eq 'L & S'
    end
    it 'returns original value when decompression unavailable' do
      expect(subject.decompress 'STUDIES').to eq 'STUDIES'
    end
  end

  context 'multiple decompressions available' do
    let(:subject_areas) { ['L&S', 'L & S', 'LATAMST', 'PHYS ED', 'PHYSED', 'PHYSIOL'] }
    it 'prefers the longest available' do
      expect(subject.decompress 'LS').to eq 'L & S'
      expect(subject.decompress 'PHYSED').to eq 'PHYS ED'
    end
    it 'transforms a partial to a full decompression' do
      expect(subject.decompress 'L&S').to eq 'L & S'
    end
  end
end
