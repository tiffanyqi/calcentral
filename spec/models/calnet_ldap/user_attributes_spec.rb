describe CalnetLdap::UserAttributes do

  let(:feed) { described_class.new(user_id: uid).get_feed_internal }

  context 'mock LDAP connection' do
    let(:uid) { '61889' }
    let(:ldap_result) do
      {
        dn: ['uid=61889,ou=people,dc=berkeley,dc=edu'],
        objectclass: ['top', 'eduPerson', 'inetorgperson', 'berkeleyEduPerson', 'organizationalperson', 'person', 'ucEduPerson'],
        o: ['University of California, Berkeley'],
        ou: ['people'],
        mail: ['oski@berkeley.edu'],
        berkeleyeduaffiliations: ['AFFILIATE-TYPE-ADVCON-STUDENT', 'AFFILIATE-TYPE-ADVCON-ATTENDEE', 'STUDENT-TYPE-NOT REGISTERED'],
        givenname: ['Oski'],
        berkeleyeduconfidentialflag: ['false'],
        berkeleyeduemailrelflag: ['false'],
        uid: ['61889'],
        berkeleyedumoddate: ['20160211155206Z'],
        berkeleyedustuid: ['11667051'],
        displayname: ['Oski BEAR'],
        sn: ['BEAR'],
        cn: ['BEAR, Oski']
      }
    end
    before { allow(CalnetLdap::Client).to receive(:new).and_return double(search_by_uid: ldap_result) }
    it 'translates LDAP attributes' do
      expect(feed[:email_address]).to eq 'oski@berkeley.edu'
      expect(feed[:first_name]).to eq 'Oski'
      expect(feed[:last_name]).to eq 'BEAR'
      expect(feed[:ldap_uid]).to eq '61889'
      expect(feed[:person_name]).to eq 'Oski BEAR'
      expect(feed[:roles][:student]).to eq true
      expect(feed[:roles][:registered]).to eq false
      expect(feed[:roles][:exStudent]).to eq false
      expect(feed[:student_id]).to eq '11667051'
    end

    context 'no affiliation data in LDAP' do
      let(:ldap_result) do
        {
          mail: ['oski@berkeley.edu'],
          uid: ['61889'],
        }
      end
      it 'returns empty roles hash' do
        expect(feed[:roles]).to be_blank
      end
    end

    context 'when both active and expired student affiliations appear' do
      let(:ldap_result) do
        {
          berkeleyeduaffiliations: ['EMPLOYEE-TYPE-STAFF', 'STUDENT-STATUS-EXPIRED', 'STUDENT-TYPE-REGISTERED'],
          uid: ['61889']
        }
      end
      it 'knows they can\'t both be right but makes no presumptions' do
        expect(feed[:roles]).not_to include :exStudent
        expect(feed[:roles]).not_to include :registered
        expect(feed[:roles]).not_to include :student
        expect(feed[:roles][:staff]).to eq true
      end
    end
  end

  context 'test user from real LDAP connection', testext: true do
    let(:uid) { '212373' }
    it 'translates attributes' do
      expect(feed[:ldap_uid]).to eq '212373'
      expect(feed[:first_name]).to eq 'AFF-GUEST'
      expect(feed[:last_name]).to eq 'TEST'
      expect(feed[:person_name]).to eq 'AFF-GUEST TEST'
    end
  end
end
