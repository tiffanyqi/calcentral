describe User::SearchUsers do

  let(:fake_uid_proxy) { CalnetCrosswalk::ByUid.new }
  let(:fake_sid_proxy) { CalnetCrosswalk::BySid.new }
  let(:fake_cs_id_proxy) { CalnetCrosswalk::ByCsId.new }

  let(:uid_proxy_ldap_uid) { nil }
  let(:uid_proxy_student_id) { nil }
  let(:uid_proxy_campus_solutions_id) { nil }

  let(:sid_proxy_ldap_uid) { nil }
  let(:sid_proxy_student_id) { nil }
  let(:sid_proxy_campus_solutions_id) { nil }

  let(:cs_id_proxy_ldap_uid) { nil }
  let(:cs_id_proxy_student_id) { nil }
  let(:cs_id_proxy_campus_solutions_id) { nil }

  before do
    allow(CalnetCrosswalk::ByUid).to receive(:new).and_return fake_uid_proxy
    allow(CalnetCrosswalk::BySid).to receive(:new).and_return fake_sid_proxy
    allow(CalnetCrosswalk::ByCsId).to receive(:new).and_return fake_cs_id_proxy

    allow(fake_uid_proxy).to receive(:lookup_ldap_uid).and_return uid_proxy_ldap_uid
    allow(fake_uid_proxy).to receive(:lookup_student_id).and_return uid_proxy_student_id
    allow(fake_uid_proxy).to receive(:lookup_campus_solutions_id).and_return uid_proxy_campus_solutions_id

    allow(fake_sid_proxy).to receive(:lookup_ldap_uid).and_return sid_proxy_ldap_uid
    allow(fake_sid_proxy).to receive(:lookup_student_id).and_return sid_proxy_student_id
    allow(fake_sid_proxy).to receive(:lookup_campus_solutions_id).and_return sid_proxy_campus_solutions_id

    allow(fake_cs_id_proxy).to receive(:lookup_ldap_uid).and_return cs_id_proxy_ldap_uid
    allow(fake_cs_id_proxy).to receive(:lookup_student_id).and_return cs_id_proxy_student_id
    allow(fake_cs_id_proxy).to receive(:lookup_campus_solutions_id).and_return cs_id_proxy_campus_solutions_id
  end
  context 'ByUid returns results' do
    let(:uid_proxy_ldap_uid) { '13579' }
    let(:uid_proxy_student_id) { '24680' }
    let(:uid_proxy_campus_solutions_id) { '9350306150' }
    it 'should return valid record for valid uid' do
      result = User::SearchUsers.new({:id => uid_proxy_ldap_uid}).search_users
      expect(result).to be_an Enumerable
      expect(result).to have(1).item
      expect(result.first['ldap_uid']).to eq uid_proxy_ldap_uid
      expect(result.first['student_id']).to eq uid_proxy_student_id
      expect(result.first['campus_solutions_id']).to eq uid_proxy_campus_solutions_id
    end
  end
  context 'BySid returns results' do
    let(:sid_proxy_ldap_uid) { '13579' }
    let(:sid_proxy_student_id) { '24680' }
    let(:sid_proxy_campus_solutions_id) { '6150935030' }
    it 'should return valid record for valid sid' do
      result = User::SearchUsers.new({:id => '24680'}).search_users
      expect(result).to have(1).item
      expect(result.first['ldap_uid']).to eq sid_proxy_ldap_uid
      expect(result.first['student_id']).to eq sid_proxy_student_id
      expect(result.first['campus_solutions_id']).to eq sid_proxy_campus_solutions_id
    end
  end
  context 'ByCsId returns results' do
    let(:cs_id_proxy_ldap_uid) { '9110492' }
    let(:cs_id_proxy_campus_solutions_id) { '5030615093' }
    it 'should return valid record for valid sid' do
      result = User::SearchUsers.new({:id => '24680'}).search_users
      expect(result).to have(1).item
      expect(result.first['ldap_uid']).to eq cs_id_proxy_ldap_uid
      expect(result.first['student_id']).to be_nil
      expect(result.first['campus_solutions_id']).to eq cs_id_proxy_campus_solutions_id
    end
  end
  context 'no results from all no proxies' do
    it 'returns no record for invalid id' do
      users = User::SearchUsers.new({:id => '12345'}).search_users
      expect(users).to be_empty
    end
  end
end
