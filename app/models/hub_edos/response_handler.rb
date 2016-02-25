module HubEdos
  module ResponseHandler

    def get_students(response)
      return [] unless response.is_a? Hash
      # We are temporarily handling both GL4 and GL5 wrapper formats for backwards compatibility.
      wrapper_keys = if response['apiResponse']
                       # GL5 format
                       %w(apiResponse response any students)
                     else
                       # GL4 format
                       %w(studentResponse students students)
                     end
      students = wrapper_keys.inject(response) { |feed, key| (feed.is_a?(Hash) && feed[key]) || [] }
      students.respond_to?(:each) ? students : []
    end

  end
end
