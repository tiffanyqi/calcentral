module CampusSolutions
  class Billing < Proxy

    include BillingFeatureFlagged
    include CampusSolutionsIdRequired

    def initialize(options = {})
      super options
      initialize_mocks if @fake
    end

    def xml_filename
      'billing_details.xml'
    end

    def build_feed(response)
      return {} unless response && (billing = response['UC_SF_ACTIVITY'])
      normalize_term_names billing
      billing
    end

    def normalize_term_names(billing)
      # Force four-digit year to the end of the term description if present at the start.
      if (term_name = billing['SUMMARY']['CURRENT_TERM']) && (m = term_name.strip.match /\A(\d{4})\s(\w+)\Z/)
        billing['SUMMARY']['CURRENT_TERM'] = "#{m[2]} #{m[1]}"
      end
      billing['ACTIVITY'].each do |activity_item|
        if (term_name = activity_item['ITEM_TERM_DESCRIPTION']) && (m = term_name.strip.match /\A(\d{4})\s(\w+)\Z/)
          activity_item['ITEM_TERM_DESCRIPTION'] = "#{m[2]} #{m[1]}"
        end
      end
    end

    def url
      "#{@settings.base_url}/UC_SF_BILLING_DETAILS.v1/Get?EMPLID=#{@campus_solutions_id}"
    end

  end
end
