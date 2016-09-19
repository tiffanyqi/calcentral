describe User::SearchUsersByUid do

  let(:user_found) do
    { studentId: '24680', ldapUid: '13579' }
  end

  let(:user_not_found) do
    { unknown: true }
  end

  it 'should return valid record for valid uid' do
    expect(User::AggregatedAttributes).to receive(:new).with('13579').and_return double(get_feed: user_found)
    model = User::SearchUsersByUid.new({:id => '13579'})
    result = model.search_users_by_uid
    expect(result[:studentId]).to eq '24680'
    expect(result[:ldapUid]).to eq '13579'
  end

  it 'returns no record for invalid uid' do
    expect(User::AggregatedAttributes).to receive(:new).with('12345').and_return double(get_feed: user_not_found)
    model = User::SearchUsersByUid.new({:id => '12345'})
    result = model.search_users_by_uid
    expect(result).to be_nil
  end

end
