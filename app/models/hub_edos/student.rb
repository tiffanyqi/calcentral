module HubEdos
  class Student < Proxy

    def url
      "#{@settings.base_url}/#{@campus_solutions_id}/all"
    end

    def json_filename
      'hub_student.json'
    end

    def build_feed(response)
      transformed_response = filter_fields(transform_address_keys(super(response)))
      {
        'student' => transformed_response
      }
    end

    def empty_feed
      {
        'student' => {}
      }
    end

    def transform_address_keys(student)
      if student['addresses'].present?
        student['addresses'].each do |address|
          address['state'] = address.delete('stateCode')
          address['postal'] = address.delete('postalCode')
          address['country'] = address.delete('countryCode')
        end
      end
      student
    end

    def filter_fields(student)
      # only include the fields that this proxy is responsible for
      return student if include_fields.nil?
      result = {}
      student.keys.each do |field|
        result[field] = student[field] if include_fields.include? field
      end
      result
    end

    def include_fields
      nil
    end

    def unwrap_response(response)
      students = super(response)
      students.any? ? students[0] : {}
    end

    def wrapper_keys
      %w(apiResponse response any students)
    end

  end
end
