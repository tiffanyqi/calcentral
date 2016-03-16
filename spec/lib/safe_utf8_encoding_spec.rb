# encoding: utf-8

describe SafeUtf8Encoding do
  subject { SafeUtf8Encoding.safe_utf8 source_string }

  context 'vanilla 7-bit ASCII' do
    let(:source_string) { 'Dix-huit boeuf ox champs oeuvres dix laissez blague.' }
    it 'should do nothing' do
      expect(subject).to eq source_string
    end
  end

  context 'UTF-8 extended characters' do
    let(:source_string) { 'Wer immer strebend sich bemüht, den können wir erlösen.' }
    it 'should do nothing' do
      expect(subject).to eq source_string
    end
  end

  context 'transcoding required' do
    shared_examples 'a non-destructive encoder' do
      it 'should return a transcoded copy, leaving the source string unmodified' do
        expect(subject).not_to eq source_string
        expect(subject.encoding.name).to eq 'UTF-8'
        expect(source_string.encoding.name).to eq 'ASCII-8BIT'
      end
    end
    context 'UTF-8 characters with generic encoding specified' do
      let(:source_string) { "M\xC3\xA9li\xC3\xA8s".force_encoding 'ASCII-8BIT' }
      it 'should correctly set UTF-8 encoding' do
        expect(subject).to eq 'Méliès'
      end
      it_should_behave_like 'a non-destructive encoder'
    end
    context 'unrecognized characters' do
      let(:source_string) { "Why you little \xC7\xFF\xFF".force_encoding 'ASCII-8BIT' }
      it 'should skip them' do
        expect(subject).to eq 'Why you little '
      end
      it_should_behave_like 'a non-destructive encoder'
    end
  end
end
