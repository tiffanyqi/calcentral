namespace :canvas do

  desc 'Get all Canvas users and sections for current terms, refresh user accounts, and update all section memberships'
  task :batch_refresh => :environment do
    canvas_worker = CanvasRefreshAllCampusData.new 'batch'
    canvas_worker.run
  end

  desc 'Get all Canvas users and sections for current terms, refresh user accounts, and add new section memberships'
  task :incremental_refresh => :environment do
    canvas_worker = CanvasRefreshAllCampusData.new 'incremental'
    canvas_worker.run
  end

  desc 'Reconfigure Canvas external apps (CALCENTRAL_XML_HOST="https://cc.example.com" CANVAS_HOSTS_TO_CALCENTRALS="https://ucb.beta.example.com=cc-dev.example.com,https://ucb.test.example.com=cc-qa.example.com")'
  task :reconfigure_external_apps => :environment do
    reachable_xml_host = ENV["CALCENTRAL_XML_HOST"]
    canvas_hosts_to_calcentrals_string = ENV["CANVAS_HOSTS_TO_CALCENTRALS"]
    if reachable_xml_host.blank?
      Rails.logger.error('Must specify CALCENTRAL_XML_HOST="https://cc.example.com"')
    elsif canvas_hosts_to_calcentrals_string.blank?
      Rails.logger.error('Must specify CANVAS_HOSTS_TO_CALCENTRALS="https://ucb.beta.example.com=cc-dev.example.com,https://ucb.test.example.com=cc-qa.example.com"')
    else
      canvas_hosts_to_calcentrals = []
      canvas_hosts_to_calcentrals_string.split(/=|,/).each_slice(2) {|pair|
        canvas_hosts_to_calcentrals.push({host: pair[0], calcentral: pair[1]})
      }
      CanvasReconfigureExternalApps.reconfigure_external_apps(reachable_xml_host, canvas_hosts_to_calcentrals)
      Rails.logger.info("Reconfigured external apps from #{reachable_xml_host} for #{canvas_hosts_to_calcentrals_string}")
    end
  end

  desc 'Repair Canvas Course SIS IDs (TERM_ID=x)'
  task :repair_course_sis_ids => :environment do
    term_id = ENV["TERM_ID"]
    if (term_id.blank?)
      Rails.logger.error("Must specify TERM_ID=YourSisTermId")
    else
      canvas_worker = CanvasRepairSections.new
      canvas_worker.repair_sis_ids_for_term(term_id)
    end
  end

end
