describe Berkeley::UserRoles do

  describe '#roles_from_cs_affiliations' do
    subject { Berkeley::UserRoles.roles_from_cs_affiliations(affiliations) }

    context 'undergraduate student' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'STUDENT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'UNDERGRAD',
              :description => 'Undergraduate Student'
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return undergraduate attributes' do
        expect(subject[:roles][:student]).to be true
        expect(subject[:ug_grad_flag]).to eq 'U'
      end
    end

    context 'graduate student' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'STUDENT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'GRADUATE',
              :description => 'Graduate Student'
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return graduate attributes' do
        expect(subject[:roles][:student]).to be true
        expect(subject[:ug_grad_flag]).to eq 'G'
      end
    end

    context 'inactive student' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'STUDENT',
              :description => ''
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'GRADUATE',
              :description => 'Graduate Student'
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return ex-student attributes' do
        expect(subject[:roles][:exStudent]).to be true
        expect(subject[:roles][:student]).to be_nil
        expect(subject[:ug_grad_flag]).to be_nil
      end
    end

    context 'former undergrad, current grad' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'STUDENT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'GRADUATE',
              :description => 'Graduate Student'
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'UNDERGRAD',
              :description => 'Undergraduate Student'
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return graduate attributes' do
        expect(subject[:roles][:exStudent]).to be_nil
        expect(subject[:roles][:student]).to be true
        expect(subject[:ug_grad_flag]).to eq 'G'
      end
    end

    context 'new and released admit' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'ADMT_UX',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return applicant attributes' do
        expect(subject[:roles][:applicant]).to be true
        expect(subject[:roles][:student]).to be_nil
      end
    end

    context 'unreleased admit or not-yet-accepted applicant' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'APPLICANT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return only unaccepted applicant status' do
        expect(subject[:roles]).to be_blank
        expect(subject[:applicant_in_process]).to be_truthy
      end
    end

    context 'ex-student and unaccepted applicant' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'STUDENT',
              :description => ''
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'APPLICANT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return only the ex-student role' do
        expect(subject[:roles]).to eq({exStudent: true})
      end
    end

    context 'retracted admit' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'APPLICANT',
              :description => ''
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          },
          {
            :type => {
              :code => 'ADMT_UX',
              :description => ''
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return only unaccepted applicant role' do
        expect(subject[:roles]).to be_blank
        expect(subject[:applicant_in_process]).to be_truthy
      end
    end

    context 'active instructor' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'INSTRUCTOR',
              :description => 'Instructor'
            },
            :statusCode => 'ACT',
            :statusDescription => 'Active',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return faculty attributes' do
        expect(subject[:roles][:faculty]).to be true
        expect(subject[:roles][:student]).to be_nil
      end
    end

    context 'advisor affiliation' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'ADVISOR',
              :description => 'Advisor'
            },
            :statusCode => status_code,
            :statusDescription => status_description,
            :fromDate => '2014-05-15'
          }
        ]
      end
      context 'active status in date range' do
        let(:status_code) { 'ACT' }
        let(:status_description) { 'Active' }
        it 'should return advisor role' do
          expect(subject[:roles]).to have(1).item
          expect(subject[:roles][:advisor]).to be true
        end
      end
      context 'inactive' do
        let(:status_code) { 'INA' }
        let(:status_description) { 'Inactive' }
        it 'should not have advisor role' do
          expect(subject[:roles]).to be_empty
        end
      end
    end

    context 'inactive instructor' do
      let(:affiliations) do
        [
          {
            :type => {
              :code => 'INSTRUCTOR',
              :description => 'Instructor'
            },
            :statusCode => 'INA',
            :statusDescription => 'Inactive',
            :fromDate => '2014-05-15'
          }
        ]
      end
      it 'should return no attributes' do
        expect(subject[:roles]).to eq({})
        expect(subject[:ug_grad_flag]).to be_nil
      end
    end

    context 'no affiliations' do
      let(:affiliations) { [] }
      it 'should return no attributes' do
        expect(subject[:roles]).to eq({})
        expect(subject[:ug_grad_flag]).to be_nil
      end
    end
  end

end
