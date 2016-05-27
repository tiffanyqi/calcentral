module CalCentralPages

  class MyProfileWorkExperienceCard < MyProfilePage

    include PageObject
    include ClassLogger
    include CalCentralPages

    h2(:heading, :xpath => '//h2[text()="Work Experience"]')
    elements(:employer, :div, :xpath => '//strong[@data-ng-bind="item.employer"]')
    button(:add, :xpath => '//button[contains(., "Add")]')
    elements(:employment_edit, :button, :xpath => '//button[contains(text(), "Edit")]')

    form(:edit_form, :name => 'cc_page_widget_profile_work_experience')
    text_area(:employer_input, :id => 'cc-page-widget-profile-work-experience-employment-descr')
    select_list(:country_select, :id => 'cc-page-widget-profile-address-country')
    text_area(:phone_input, :id => 'cc-page-widget-profile-work-experience-phone-number')
    text_area(:start_date_input, :id => 'cc-page-widget-profile-work-experience-start-date')
    text_area(:end_date_input, :id => 'cc-page-widget-profile-work-experience-end-date')
    paragraph(:date_validation_error, :xpath => '//p[contains(text(),"Please use mm/dd/yyyy date format")]')
    text_area(:title_input, :id => 'cc-page-widget-profile-work-experience-job-title')
    elements(:fraction_radio_button, :radio_button, :xpath => '//div[@data-ng-repeat="value in employFracValues"]//input')
    text_area(:pay_rate_input, :id => 'cc-page-widget-profile-work-experience-ending-pay-rate')
    select_list(:currency_select, :id => 'cc-page-widget-profile-work-experience-currency-type')
    text_area(:hours_per_week_input, :id => 'cc-page-widget-profile-work-experience-hours-per-week')
    select_list(:pay_frequency_select, :id => 'cc-page-widget-profile-work-experience-pay-frequency')
    button(:save, :xpath => '//button[contains(.,"Save")]')
    button(:cancel, :xpath => '//button[contains(.,"Cancel")]')
    button(:delete, :xpath => '//button[text()="Delete work experience"]')

    radio_button(:full_time_radio, :xpath => '//span[text()="Full Time"]/preceding-sibling::input')
    radio_button(:three_quarter_time_radio, :xpath => '//span[text()="3/4 Time"]/preceding-sibling::input')
    radio_button(:half_time_radio, :xpath => '//span[text()="Half Time"]/preceding-sibling::input')
    radio_button(:one_quarter_time_radio, :xpath => '//span[text()="1/4 Time"]/preceding-sibling::input')

    def load_page
      logger.debug 'Loading profile work experience page'
      navigate_to "#{WebDriverUtils.base_url}/profile/work-experience"
    end

    def all_employers
      employer_elements.map &:text
    end

    def fraction_radio(job_data)
      case job_data[:fraction]
        when '100'
          fraction_radio_button_elements[0]
        when '75'
          fraction_radio_button_elements[1]
        when '50'
          fraction_radio_button_elements[2]
        when '25'
          fraction_radio_button_elements[3]
        else
          nil
      end
    end

    def click_add_job
      click_cancel if cancel_element.visible?
      add_element.when_visible WebDriverUtils.page_event_timeout
      click_element add_element
    end

    def click_edit(index)
      click_cancel if cancel_element.visible?
      employment_edit_elements[index].when_visible WebDriverUtils.page_event_timeout
      click_element employment_edit_elements[index]
    end

    def click_save
      save_element.when_visible WebDriverUtils.page_event_timeout
      click_element save_element
    end

    def click_cancel
      cancel_element.when_visible WebDriverUtils.page_event_timeout
      click_element cancel_element
      add_element.when_visible WebDriverUtils.page_event_timeout
    end

    def click_delete_job
      delete_element.when_visible WebDriverUtils.page_event_timeout
      click_element delete_element
    end

    def inputs_max(inputs)
      {
          employer: inputs['employer'],
          phone: inputs['phone'],
          title: inputs['title']
      }
    end

    def job_data(job)
      {
          employer: job['employer'],
          country: job['country'],
          phone: job['phone'],
          start_date: job['startDate'],
          end_date: job['endDate'],
          title: job['title'],
          fraction: job['fraction'],
          rate: job['rate'],
          currency: job['currency'],
          hours: job['hours'],
          pay_frequency: job['payFrequency']
      }
    end

    def enter_job(job_data)
      logger.info "Entering job data for employer '#{job_data[:employer]}'"
      edit_form_element.when_visible WebDriverUtils.page_event_timeout
      clear_and_type(employer_input_element, job_data[:employer])
      self.country_select = job_data[:country] unless job_data[:country].blank?
      scroll_to_bottom
      clear_and_type(phone_input_element, job_data[:phone])
      clear_and_type(start_date_input_element, job_data[:start_date])
      clear_and_type(end_date_input_element, job_data[:end_date])
      clear_and_type(title_input_element, job_data[:title])
      click_element fraction_radio(job_data) unless job_data[:fraction].blank?
      clear_and_type(hours_per_week_input_element, job_data[:hours])
      self.currency_select = job_data[:currency]
      clear_and_type(pay_rate_input_element, job_data[:rate])
      self.pay_frequency_select = job_data[:pay_frequency]
    end

    def trimmed_input(field_max, input)
      # returns the max allowed in a field regardless of what a user enters
      input.slice(0..(field_max.to_i - 1)).strip
    end

    def verify_job(job_data, index, inputs)
      logger.info 'Verifying job'
      wait_until(WebDriverUtils.page_event_timeout, "Visible employer at index #{index} is #{employer_elements[index].text}") do
        employer_elements[index].text == trimmed_input(inputs_max(inputs)[:employer], job_data[:employer])
      end
      # TODO: verify the start / end dates on the work experience list
      click_edit index
      wait_until(1) { employer_input == trimmed_input(inputs_max(inputs)[:employer], job_data[:employer]) }
      wait_until(1) { country_select == job_data[:country] }
      wait_until(1) { phone_input == trimmed_input(inputs_max(inputs)[:phone], job_data[:phone]) }
      # TODO: verify the start / end dates on the work experience edit form
      wait_until(1) { title_input == trimmed_input(inputs_max(inputs)[:title], job_data[:title]) }
      wait_until(1) { fraction_radio(job_data).selected? }
      wait_until(1) { pay_rate_input == job_data[:rate] }
      wait_until(1) { currency_select == job_data[:currency] }
      wait_until(1) { hours_per_week_input == job_data[:hours] }
      wait_until(1) { pay_frequency_select == job_data[:pay_frequency] }
    end

    def add_new_job(jobs_added, job)
      logger.info 'Adding a new job'
      job_data = job_data job
      click_add_job
      enter_job job_data
      click_save
      # Add the new job to the collection of jobs added thus far
      jobs_added << job
      job_data
    end

    def edit_job(jobs_added, existing_job, edited_job)
      logger.info 'Editing an existing job'
      job_data = job_data edited_job
      index = get_job_index(jobs_added, existing_job)
      click_edit index
      enter_job job_data edited_job
      click_save
      # To keep track of jobs in the UI, replace the original job with the edited job
      jobs_added.map! { |j| j == existing_job ? edited_job : j }
      job_data
    end

    def delete_job(index)
      logger.debug "Deleting job at index #{index}"
      jobs = employer_elements.length
      click_edit index
      click_delete_job
      sleep 5
      wait_until(WebDriverUtils.page_event_timeout) { employer_elements.length == jobs - 1 }
    end

    def delete_all_jobs
      job_count = employer_elements.length
      logger.debug "There are #{job_count} jobs to delete"
      (1..job_count).each do
        job_count = employer_elements.length
        delete_job 0
      end
    end

    def get_job_index(jobs_added, job)
      wait_until(WebDriverUtils.page_load_timeout) { employer_elements.any? }
      sorted_jobs(jobs_added).index job
    end

    def sorted_jobs(jobs_added)
      # Jobs with start dates are sorted by start date descending
      jobs_with_dates = (jobs_added.select { |j| !job_data(j)[:start_date].blank? }).sort_by { |j| job_data(j)[:start_date] }
      jobs_with_dates.reverse!
      # Jobs with nil start dates are sorted by creation date descending
      jobs_without_dates = (jobs_added.select { |j| job_data(j)[:start_date].blank? }).sort_by { |j| job_data(j)[:index] }
      jobs_without_dates.reverse!
      # Jobs without start dates come before jobs with dates
      sorted_jobs = jobs_without_dates + jobs_with_dates
      logger.info "Expected employer sequence in the UI is #{sorted_jobs.map { |j| job_data(j)[:employer] }}"
      sorted_jobs
    end

  end
end
