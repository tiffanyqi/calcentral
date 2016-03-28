describe Berkeley::GradeOptions do

  describe '.grade_option_from_basis' do
    subject { described_class.grade_option_from_basis(grading_basis) }
    %w(GRD).each do |basis|
      context "when #{basis} basis" do
        let(:grading_basis) {basis}
        it {should eq 'Letter'}
      end
    end
    %w(LAW).each do |basis|
      context "when #{basis} basis" do
        let(:grading_basis) {basis}
        it {should eq 'Law'}
      end
    end
    %w(CNC EPN PNP).each do |basis|
      context "when #{basis} basis" do
        let(:grading_basis) {basis}
        it {should eq 'P/NP'}
      end
    end
    %w(ESU SUS).each do |basis|
      context "when #{basis} basis" do
        let(:grading_basis) {basis}
        it {should eq 'S/U'}
      end
    end
    %w(BMT CNV NON OPT).each do |basis|
      context "when #{basis} basis" do
        let(:grading_basis) {basis}
        it {should eq ''}
      end
    end
  end

  describe '.grade_option_for_enrollment' do
    subject { described_class.grade_option_for_enrollment(credit_code, pnp_flag) }
    [nil, '  ', 'N'].each do |pnp_cd|
      context "when P/NP flag is '#{pnp_cd}'" do
        let(:pnp_flag) {pnp_cd}
        [nil, 'PF', 'SF', '2T', '3T', 'TT', 'PT', 'ST'].each do |cred_cd|
          context "when #{cred_cd} credit code" do
            let(:credit_code) {cred_cd}
            it {should eq 'Letter'}
          end
        end
        # WARNING: The registrar documentation on "PF" and "PN" seems to have them swapped.
        %w(PN).each do |cred_cd|
          context "when #{cred_cd} credit code" do
            let(:credit_code) {cred_cd}
            it {should eq 'P/NP'}
          end
        end
        %w(SU).each do |cred_cd|
          context "when #{cred_cd} credit code" do
            let(:credit_code) {cred_cd}
            it {should eq 'S/U'}
          end
        end
        %w(T1 T2 T3 TP TS TX).each do |cred_cd|
          context "when #{cred_cd} credit code" do
            let(:credit_code) {cred_cd}
            it {should eq 'IP'}
          end
        end
      end
    end

    context 'when P/NP flag is Y' do
      let(:pnp_flag) {'Y'}
      [nil, 'PF', 'PN'].each do |cred_cd|
        context "when #{cred_cd} credit code" do
          let(:credit_code) {cred_cd}
          it {should eq 'P/NP'}
        end
      end
      %w(SF SU).each do |cred_cd|
        context "when #{cred_cd} credit code" do
          let(:credit_code) {cred_cd}
          it {should eq 'S/U'}
        end
      end
      # We have no data for these.
      %w(2T 3T TT PT ST T1 T2 T3 TP TS TX).each do |cred_cd|
        context "when #{cred_cd} credit code" do
          let(:credit_code) {cred_cd}
          it {should eq ''}
        end
      end
    end
  end

end
