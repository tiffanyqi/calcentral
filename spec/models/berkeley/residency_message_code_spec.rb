describe Berkeley::ResidencyMessageCode do

  describe '.residency_message_code' do
    subject { described_class.residency_message_code(slr_status, residency_status, tuition_exception) }

    describe 'not completed' do
      %w(N).each do |slr|
        context "when #{slr} slr_status" do
          let(:slr_status) {slr}
          ['', 'PEND'].each do |res|
            let(:residency_status) { res }
            let(:tuition_exception) { 'ANYTHING' }
            it {should eq '2000'}
          end
        end
      end

      %w(A).each do |slr|
        context "when #{slr} slr_status" do
          let(:slr_status) {slr}
          ['', 'PEND'].each do |res|
            let(:residency_status) { res }
            let(:tuition_exception) { 'ANYTHING' }
            it {should eq '2001'}
          end
        end
      end

      %w(R).each do |slr|
        context "when #{slr} slr_status" do
          let(:slr_status) {slr}
          ['', 'PEND'].each do |res|
            let(:residency_status) { res }
            let(:tuition_exception) { 'ANYTHING' }
            it {should eq '2002'}
          end

        end
      end
    end

    describe 'completed' do
      ['D', 'Y'].each do |slr|
        context "when #{slr} slr_status" do
          let(:slr_status) {slr}

          %w(NON).each do |res|
            context "when #{res} residency_status" do
              let(:residency_status) {res}
              let(:tuition_exception) { '' }
              it {should eq '2004'}

              ['RA', 'RV'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2005'}
                end
              end

              ['RP'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2007'}
                end
              end

              ['RD', 'RDRA', 'RE', 'RF', 'RL'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2009'}
                end
              end

              ['RM'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2010'}
                end
              end
            end
          end

          %w(RES).each do |res|
            context "when #{res} residency_status" do
              let(:residency_status) {res}
              let(:tuition_exception) { '' }
              it {should eq '2003'}

              ['R8', 'RB', 'RP'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2006'}
                end
              end

              ['RD', 'RDO', 'RDRA'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2008'}
                end
              end

              ['R6', 'R9'].each do |tuit|
                context "when #{tuit} tuition_exception" do
                  let(:tuition_exception) {tuit}
                  it {should eq '2011'}
                end
              end
            end
          end

        end
      end
    end

    describe 'no slr_status' do
      [''].each do |slr|
        context "when #{slr} slr_status" do
          let(:slr_status) {slr}
          let(:residency_status) { 'RES' }
          let(:tuition_exception) { 'ANYTHING' }
          it {should eq ''}
        end
      end
    end

    describe 'no match' do
      let(:slr_status) {'D'}
      let(:residency_status) { 'RES' }
      let(:tuition_exception) { 'RE' }
      it {should eq ''}
    end
  end
end
