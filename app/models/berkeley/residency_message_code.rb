module Berkeley
  module ResidencyMessageCode
    extend self

    def residency_message_code(slr_status, residency_status, tuition_exception)
      slr_status.strip! if slr_status
      residency_status.strip! if residency_status
      tuition_exception.strip! if tuition_exception

      case slr_status
        when 'N' # Not submitted
          case residency_status
            when '', 'PEND' # none or Pending
              '2000'
            else
              ''
          end
        when 'A' # Awaiting
          case residency_status
            when '', 'PEND'
              '2001'
            else
              ''
          end
        when 'R' # Received
          case residency_status
            when '', 'PEND'
              '2002'
            else
              ''
          end
        when 'D', 'Y' # Completed
          case residency_status
            when 'NON' # Non-resident
              case tuition_exception
                when ''
                  '2004'
                when 'RA', 'RV' # AB540, Veteran/Dependent of Veteran
                  '2005'
                when 'RP' # Dependent Deceased Law Enf/FF
                  '2007'
                when 'RD', 'RDRA', 'RE', 'RF', 'RL' # Attorney Waiver, DACA Students Not CA or AB540, UC Employee Outside of CA, Faculty Spouse or Dependent, Dep of UC Emp Outside CA
                  '2009'
                when 'RM' # Military Member/Dep/Spouse
                  '2010'
                else
                  ''
              end
            when 'RES' # Resident
              case tuition_exception
                when ''
                  '2003'
                when 'R8', 'RB', 'RP' # Credentialed Public School Emp, Grad Bureau Indian Affairs Sch, Dependent Deceased Law Enf/FF
                  '2006'
                when 'RD', 'RDO', 'RDRA' # Attorney Waiver, DACA Students Not CA or AB540,	Pending I-485 & AB540 Eligible
                  '2008'
                when 'R6', 'R9' # Dependent of CA Res Parent, Chula Vista Athlete
                  '2011'
                else
                  ''
              end
            else
              ''
          end
        else
          ''
      end
    end
  end
end
