describe Bearfacts::Profile do

  it_should_behave_like 'a student data proxy' do
    let!(:proxy_class) { Bearfacts::Profile }
    let!(:feed_key) { 'studentProfile' }
  end
  it_should_behave_like 'a proxy for legacy users only'

end
