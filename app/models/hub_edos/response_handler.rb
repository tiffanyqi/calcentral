module HubEdos
  module ResponseHandler

    def get_students(response)
      return [] unless response.is_a? Hash
      students = wrapper_keys.inject(response) { |feed, key| (feed.is_a?(Hash) && feed[key]) || [] }
      students.respond_to?(:each) ? students : []
    end

    def wrapper_keys
      %w(apiResponse response any students)
    end

  end
end
