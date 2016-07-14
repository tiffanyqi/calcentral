module MyAcademics
  class CollegeAndLevel
    include AcademicsModule
    include ClassLogger
    include User::Student

    def merge(data)
      # TEMPORARY TRANSITIONAL LOGIC BETWEEN SPRING 2016 AND FALL 2016.
      # New incoming Fall 2016 users will have no BearFacts API data.
      # Legacy users may have Fall 2016 CS/Hub academic status data, but it will be incomplete until GL5.4 conversions.
      # Legacy users may also have Summer 2016 BearFacts RegStatus and Spring 2016 BearFacts College-Level-Major data,
      # but neither will be exposed in CalCentral as of Fall 2016.
      college_and_level = hub_college_and_level
      prefer_legacy_data = Settings.features.cs_academic_profile_prefers_legacy
      if (current_term.legacy? || prefer_legacy_data) && legacy_user?
        legacy_college_and_level = bearfacts_college_and_level
        if college_and_level[:empty] || !current_term.is_summer || (prefer_legacy_data && !legacy_college_and_level[:empty])
          college_and_level = legacy_college_and_level
        end
      end
      # If we have no profile at all, consider the no-profile to be active for the current term.
      if college_and_level[:empty]
        college_and_level[:termName] = Berkeley::Terms.fetch.current.to_english
        college_and_level[:isCurrent] = true
      else
        # The key name is a bit misleading, since the profile might be for a future term.
        # TODO Use this in place of the overly complex 'isProfileCurrent' front-end logic.
        college_and_level[:isCurrent] = !profile_in_past?(college_and_level)
      end
      data[:collegeAndLevel] = college_and_level
    end

    def bearfacts_college_and_level
      response = Bearfacts::Profile.new(user_id: @uid).get
      feed = response.delete :feed
      # The Bear Facts API can return empty profiles if the user is no longer (or not yet) considered an active student.
      # Partial profiles can be returned for incoming students around the start of the term.
      if (feed.nil? || feed['studentProfile']['studentGeneralProfile'].blank? || feed['studentProfile']['ugGradFlag'].blank?)
        response[:empty] = true
      else
        response.merge! parse_bearfacts_feed(feed)
      end
      response
    end

    def hub_college_and_level
      response = HubEdos::AcademicStatus.new(user_id: @uid).get
      if (status = parse_hub_academic_status response)
        response[:careers] = parse_hub_careers status
        response[:cumulativeUnits] = parse_hub_transfer_credit_cumulative_units status
        response[:level] = parse_hub_level status
        response[:termName] = parse_hub_term_name status
        response[:termsInAttendance] = status['termsInAttendance'].to_s
        response.merge! parse_hub_plans status
      else
        response[:empty] = true
      end
      response
    end

    def parse_hub_careers(status)
      [].tap do |careers|
        if (career = status['studentCareer'].try(:[], 'academicCareer').try(:[], 'description'))
          careers << career
        end
      end
    end

    def parse_hub_transfer_credit_cumulative_units(status)
      return {} unless status['cumulativeUnits'].present?
      status['cumulativeUnits']
    end

    def parse_hub_level(status)
      status['currentRegistration'].try(:[], 'academicLevel').try(:[], 'level').try(:[], 'description')
    end

    def parse_hub_plans(status)
      majors = []
      minors = []
      plans = []
      status['studentPlans'].each do |student_plan|
        plan_primary = !!student_plan['primary']
        if (academic_plan = student_plan['academicPlan'])
          college = academic_plan['academicProgram'].try(:[], 'program').try(:[], 'description')
          plan_description = academic_plan['plan'].try(:[], 'description')
          case academic_plan['type'].try(:[], 'code')
            when 'MAJ'
              majors << {
                college: college,
                major: plan_description
              }
            when 'MIN'
              minors << {
                college: college,
                minor: plan_description
              }
          end

          if (plan_code = academic_plan['plan'].try(:[], 'code'))
            plans << {
              code: plan_code,
              primary: plan_primary
            }
          end
        end
      end
      {
        majors: majors,
        minors: minors,
        plans: plans,
        roles: {
          fpf: plans.any? { |plan| plan[:code] == '25000FPFU' }
        }
      }
    end

    def parse_hub_term_name(status)
      Berkeley::TermCodes.normalized_english status['currentRegistration'].try(:[], 'term').try(:[], 'name')
    end

    def parse_bearfacts_feed(feed)
      careers = []
      ug_grad_flag = feed['studentProfile']['ugGradFlag'].to_text
      case ug_grad_flag.upcase
        when 'U'
          careers << 'Undergraduate'
        when 'G'
          careers << 'Graduate'
        else
          logger.error("Unknown ugGradFlag '#{ug_grad_flag}' for user #{@uid}")
          return {}
      end

      general_profile = feed['studentProfile']['studentGeneralProfile']

      level = general_profile['corpEducLevel'].to_text.titleize
      nonAPLevel = general_profile['nonAPLevel'].to_text.titleize
      futureTBLevel = general_profile['futureTBLevel'].to_text.titleize

      majors = []
      primary_college_abbv = general_profile['collegePrimary'].to_text
      primary_college = Berkeley::Colleges.get(primary_college_abbv)
      primary_major = Berkeley::Majors.get(general_profile['majorPrimary'].to_text)

      # this code block is not very DRY, but that makes it easier to understand the wacky requirements. See CLC-2017 for background.
      if primary_college_abbv.in?(['GRAD DIV', 'LAW', 'CONCURNT'])
        if primary_major == 'Double' || primary_major == 'Triple'
          majors << {
            :college => (general_profile['collegeSecond'].blank? ? primary_college : Berkeley::Colleges.get(general_profile['collegeSecond'].to_text)),
            :major => Berkeley::Majors.get(general_profile['majorSecond'].to_text)
          }
          majors << {
            :college => Berkeley::Colleges.get(general_profile['collegeThird'].to_text),
            :major => Berkeley::Majors.get(general_profile['majorThird'].to_text)
          }
          if primary_major == 'Triple'
            majors << {
              :college => Berkeley::Colleges.get(general_profile['collegeFourth'].to_text),
              :major => Berkeley::Majors.get(general_profile['majorFourth'].to_text)
            }
          end
        else
          majors << {
            :college => primary_college,
            :major => primary_major
          }
        end
      else
        if primary_major == 'Double' || primary_major == 'Triple'
          majors << {
            :college => primary_college,
            :major => Berkeley::Majors.get(general_profile['majorSecond'].to_text)
          }
          majors << {
            :college => '',
            :major => Berkeley::Majors.get(general_profile['majorThird'].to_text)
          }
          if primary_major == 'Triple'
            majors << {
              :college => '',
              :major => Berkeley::Majors.get(general_profile['majorFourth'].to_text)
            }
          end
        else
          majors << {
            :college => primary_college,
            :major => primary_major
          }
        end
      end
      term_name = "#{feed['studentProfile']['termName'].to_text} #{feed['studentProfile']['termYear'].to_text}"
      feed = {
        careers: careers,
        level: level,
        futureTelebearsLevel: futureTBLevel,
        majors: majors,
        termName: term_name
      }
      feed[:nonApLevel] = nonAPLevel if nonAPLevel.present? && nonAPLevel != level
      feed
    end

    def profile_in_past?(profile)
      if !profile[:empty] && (term = Berkeley::TermCodes.from_english profile[:termName])
        time_bucket(term[:term_yr], term[:term_cd]) == 'past'
      else
        false
      end
    end
  end
end
