describe Links::MyCampusLinks do

  context 'user roles that can see a particular link' do
    let(:roles_for_link) {
      roles_for_link = []
      roles.each { |role| roles_for_link << double(slug: role) }
      Links::MyCampusLinks.new.get_roles_for_link double user_roles: roles_for_link
    }
    context 'ex-students' do
      subject { roles_for_link['exStudent'] }
      context 'student gets a link' do
        let(:roles) { %w(student exStudent) }
        it { should be true }
      end
      context 'no link for student role' do
        let(:roles) { %w(applicant staff faculty student) }
        it { should be false }
      end
    end
  end

end
