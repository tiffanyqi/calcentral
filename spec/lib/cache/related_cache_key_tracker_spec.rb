describe Cache::RelatedCacheKeyTracker do

  class RelatedKeyTestClass
    include ClassLogger
    include Cache::CachedFeed
    include Cache::RelatedCacheKeyTracker
    attr_accessor :extra_param

    def initialize(uid)
      @uid = uid
    end

    def instance_key
      "#{@uid}-#{self.extra_param}"
    end

    def get_feed_internal
      {}
    end
  end

  let(:oski_past_data) do
    test_class.new('61889').tap do |instance|
      instance.extra_param = '1066'
    end
  end

  let(:oski_future_data) do
    test_class.new('61889').tap do |instance|
      instance.extra_param = '2525'
    end
  end

  let(:oski_related_keys) { "#{test_class}/related-cache-keys-61889" }

  context 'no JSON-added caching' do
    let(:test_class) { RelatedKeyTestClass }

    before do
      oski_past_data.get_feed
      oski_future_data.get_feed
    end

    it 'tracks multiple cache keys for a given class and UID' do
      related_keys = Rails.cache.read oski_related_keys
      expect(related_keys).to eq({
        "#{test_class}/61889-1066" => 1,
        "#{test_class}/61889-2525" => 1
      })
      related_keys.keys.each { |key| expect(Rails.cache.read key).not_to be_nil }
    end

    it 'expires tracked keys on request' do
      related_keys = Rails.cache.read oski_related_keys
      test_class.expire '61889'
      related_keys.keys.each { |key| expect(Rails.cache.read key).to be_nil }
      expect(Rails.cache.read oski_related_keys).to be_nil
    end
  end

  context 'JSON-added caching' do
    class RelatedKeyJsonTestClass < RelatedKeyTestClass
      include Cache::JsonAddedCacher
    end

    let(:test_class) { RelatedKeyJsonTestClass }

    before do
      oski_past_data.get_feed_as_json
      oski_future_data.get_feed_as_json
    end

    it 'tracks regular and JSONified cache keys for a given class and UID' do
      related_keys = Rails.cache.read oski_related_keys
      expect(related_keys).to eq({
        "#{test_class}/61889-1066" => 1,
        "#{test_class}/61889-2525" => 1,
        "#{test_class}/json-61889-1066" => 1,
        "#{test_class}/json-61889-2525" => 1
      })
      related_keys.keys.each { |key| expect(Rails.cache.read key).not_to be_nil }
    end

    it 'expires regular and JSONified keys on request' do
      related_keys = Rails.cache.read oski_related_keys
      test_class.expire '61889'
      related_keys.keys.each { |key| expect(Rails.cache.read key).to be_nil }
      expect(Rails.cache.read oski_related_keys).to be_nil
    end
  end
end
