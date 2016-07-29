describe 'My Finances legacy student financials', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser

      test_users = UserUtils.load_test_users.select { |user| user['financesData'] }
      testable_users = []
      test_output_heading = ['UID', 'Finances Tab', 'CARS Data', 'Acct Bal', 'Amt Due Now', 'Past Due', 'Future Activity',
                             'On DPP', 'Norm Install', 'DPP Past Due', 'Adjustments', 'Awards', 'Charges', 'Payments',
                             'Refunds', 'Waivers', 'Has Unapplied Award', 'Has Partial Payment', 'Has Potential Disburse']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      @splash_page = CalCentralPages::SplashPage.new driver
      @status_api = ApiMyStatusPage.new driver
      @my_finances = CalCentralPages::MyFinancesPages::MyFinancesDetailsPage.new driver
      @dashboard_page = CalCentralPages::MyDashboardPage.new driver

      test_users.each do |user|
        uid = user['uid']
        logger.info "UID is #{uid}"

        has_finances_tab = false
        has_cars_data = false
        acct_bal = nil
        amt_due_now = nil
        has_past_due_amt = false
        has_future_activity = false
        is_dpp = false
        has_dpp_balance = false
        is_dpp_past_due = false
        adjustment_count = nil
        award_count = nil
        charge_count = nil
        payment_count = nil
        refund_count = nil
        waiver_count = nil
        has_unapplied_award = false
        has_partial_payment = false
        has_potential_disburse = false

        begin
          @splash_page.load_page
          @splash_page.basic_auth uid
          @status_api.get_json driver

          # Get data from financials API
          fin_api = ApiMyFinancialsPage.new driver
          fin_api.get_json driver
          fin_cs_api = ApiCSBillingPage.new driver
          fin_cs_api.get_json driver

          @my_finances.load_page

          my_fin_no_cars_msg = @my_finances.no_cars_data_msg?
          has_finances_tab = @status_api.has_finances_tab?

          if (has_cars_data = fin_api.has_cars_data?)

            testable_users << uid

            @my_finances.load_summary

            # ACCOUNT SUMMARY CARD

            # Balance

            my_fin_acct_bal = @my_finances.account_balance
            it("shows the right account balance for UID #{uid}") { expect(my_fin_acct_bal).to eql(fin_api.amt_to_s fin_api.account_balance) }

            if fin_api.account_balance > 0
              acct_bal = 'Positive'
              my_fin_balance_transactions = @my_finances.visible_transactions_sum_str
              it("shows the open charges for UID #{uid}") { expect(my_fin_balance_transactions).to eql(fin_api.amt_to_s fin_api.transactions_sum(fin_api.open_charges)) }

            elsif fin_api.account_balance == 0
              acct_bal = 'Zero'
              # Expect 'zero balance' message, but infrequent ODSQA refresh can leave balance and transactions out of sync, causing intermittent test failures

            elsif fin_api.account_balance < 0
              acct_bal = 'Negative'
              # Expect 'credit balance' message, but infrequent ODSQA refresh can leave balance and transactions out of sync, causing intermittent test failures
            end

            # Amount due now

            my_fin_amt_due_now = @my_finances.amt_due_now
            it("shows the right amount due now for UID #{uid}") { expect(my_fin_amt_due_now).to eql(fin_api.amt_to_s fin_api.min_amt_due) }

            my_fin_amt_due_label = @my_finances.amt_due_now_label

            if fin_api.min_amt_due > 0
              amt_due_now = 'Positive'
              it("shows the label Amount Due Now for UID #{uid}") { expect(my_fin_amt_due_label).to include('Amount Due Now') }

            elsif fin_api.min_amt_due == 0
              amt_due_now = 'Zero'
              it("shows the label Amount Due Now for UID #{uid}") { expect(my_fin_amt_due_label).to include('Amount Due Now') }

            elsif fin_api.min_amt_due < 0
              amt_due_now = 'Negative'
              it("shows the label Credit Balance for UID #{uid}") { expect(my_fin_amt_due_label).to include('Credit Balance') }

            else
              it("shows a non-numeric minimum amount due for UID #{uid}") { fail }
            end

            # Past due amount

            if fin_api.past_due_amt > 0
              has_past_due_amt = true
              my_fin_past_due_bal = @my_finances.past_due_amt
              it("shows the past due amount for UID #{uid}") { expect(my_fin_past_due_bal).to eql(fin_api.amt_to_s fin_api.past_due_amt) }
            end

            # Charges not yet due

            if fin_api.future_activity > 0
              has_future_activity = true
              my_fin_future_activity = @my_finances.charges_not_due
              it("shows the charges not yet due for UID #{uid}") { expect(my_fin_future_activity).to eql(fin_api.amt_to_s fin_api.future_activity) }
            end

            # Make payment link

            my_fin_pmt_link = @my_finances.make_payment_link?
            fin_api.account_balance.zero? ?
                it("shows no make payment link for UID #{uid}") { expect(my_fin_pmt_link).to be false } :
                it("shows a make payment link for UID #{uid}") { expect(my_fin_pmt_link).to be true } unless fin_api.account_balance.zero?

            # Last statement balance

            @my_finances.show_last_statement_bal

            my_fin_last_bal = @my_finances.last_statement_balance
            it("shows the right last statement balance for UID #{uid}") { expect(my_fin_last_bal).to eql(fin_api.amt_to_s fin_api.last_statement_balance) }

            # Deferred payment plan

            shows_dpp_bal = @my_finances.dpp_bal?
            shows_dpp_msg = @my_finances.dpp_text?
            shows_dpp_install_amt = @my_finances.dpp_norm_install?

            if fin_api.is_on_dpp?
              is_dpp = true
              is_dpp_past_due = true if fin_api.is_dpp_past_due?

              my_fin_dpp_bal = @my_finances.dpp_balance

              it("shows DPP balance for UID #{uid}") { expect(my_fin_dpp_bal).to eql(fin_api.amt_to_s fin_api.dpp_balance) }
              it("shows DPP informational text for UID #{uid}") { expect(shows_dpp_msg).to be true }

              if fin_api.dpp_balance > 0
                has_dpp_balance = true
                my_fin_dpp_install = @my_finances.dpp_normal_install

                it("shows DPP normal installment amount for UID #{uid}") { expect(my_fin_dpp_install).to eql(fin_api.amt_to_s fin_api.dpp_norm_install_amt) }

              else
                it("shows no DPP normal installment amount for UID #{uid}") { expect(shows_dpp_install_amt).to be false }
              end

            else
              it("shows no DPP balance for UID #{uid}") { expect(shows_dpp_bal).to be false }
              it("shows no DPP informational text for UID #{uid}") { expect(shows_dpp_msg).to be false }
            end

            # TRANSACTION DETAIL CARD

            @my_finances.search('All Transactions', nil, '', '', '')
            @my_finances.show_all

            transactions_count_in_ui = @my_finances.visible_transaction_count
            it("shows all the transactions for UID #{uid}") { expect(transactions_count_in_ui).to eql(fin_api.all_transactions.length) }

            adjustments = fin_api.transactions_by_type(fin_api.all_transactions, 'Adjustment')
            adjustment_count = adjustments.length
            logger.info "There are #{adjustment_count} adjustments"
            if adjustments.any?
              adjustment = adjustments.first
              adjustment_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(adjustment)

              logger.debug "Checking adjustment on #{adjustment_date}"

              @my_finances.search('Date Range', nil, adjustment_date, adjustment_date, fin_api.trans_id(adjustment))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail

                ui_adj_date = @my_finances.trans_date
                ui_adj_desc = @my_finances.trans_desc
                ui_adj_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_adj_id = @my_finances.trans_id
                ui_adj_due_date = @my_finances.trans_due_date
                ui_adj_dept = @my_finances.trans_dept
                ui_adj_term = @my_finances.trans_term
                ui_has_adj_disburse = @my_finances.trans_disburse_date?
                ui_adj_ref_method = @my_finances.trans_ref_method?
                ui_adj_ref_date = @my_finances.trans_ref_date?
                ui_adj_ref_action = @my_finances.trans_ref_action?
                ui_adj_ref_void = @my_finances.trans_ref_void?

                it("shows the adjustment date for UID #{uid}") { expect(ui_adj_date).to eql(fin_api.formatted_date fin_api.trans_date(adjustment)) }
                it("shows the adjustment description for UID #{uid}") { expect(ui_adj_desc).to eql(fin_api.trans_desc(adjustment)) }
                it("shows the adjustment amount for UID #{uid}") { expect(ui_adj_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(adjustment)) }
                it("shows the adjustment transaction ID for UID #{uid}") { expect(ui_adj_id).to eql("Transaction #: #{fin_api.trans_id(adjustment)}") }
                it("shows the adjustment due date for UID #{uid}") { expect(ui_adj_due_date).to eql("Due Date: #{fin_api.formatted_date fin_api.trans_due_date(adjustment)}") }
                it("shows the adjustment department for UID #{uid}") { expect(ui_adj_dept).to include("Department: #{fin_api.trans_dept(adjustment)}") }
                it("shows the adjustment term for UID #{uid}") { expect(ui_adj_term).to eql("Term: #{fin_api.trans_term(adjustment)}") }
                it("shows no adjustment potential disbursement date for UID #{uid}") { expect(ui_has_adj_disburse).to be false }
                it("shows no adjustment refund method for UID #{uid}") { expect(ui_adj_ref_method).to be false }
                it("shows no adjustment refund date for UID #{uid}") { expect(ui_adj_ref_date).to be false }
                it("shows no adjustment refund action for UID #{uid}") { expect(ui_adj_ref_action).to be false }
                it("shows no adjustment refund void date for UID #{uid}") { expect(ui_adj_ref_void).to be false }

              else
                logger.warn "Found more than one adjustment on #{adjustment_date}, skipping"
              end
            end

            awards = fin_api.transactions_by_type(fin_api.all_transactions, 'Award')
            award_count = awards.length
            logger.info "There are #{award_count} awards"
            if awards.any?
              award = awards.first
              award_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(award)

              logger.debug "Checking award on #{award_date}"

              @my_finances.search('Date Range', nil, award_date, award_date, fin_api.trans_id(award))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail

                ui_award_date = @my_finances.trans_date
                ui_award_desc = @my_finances.trans_desc
                ui_award_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_award_id = @my_finances.trans_id
                ui_award_has_due_date = @my_finances.trans_due_date?
                ui_award_dept = @my_finances.trans_dept
                ui_award_term = @my_finances.trans_term
                ui_award_has_unapplied = @my_finances.trans_unapplied?
                ui_award_has_disburse = @my_finances.trans_disburse_date?
                ui_has_award_ref_method = @my_finances.trans_ref_method?
                ui_has_award_ref_date = @my_finances.trans_ref_date?
                ui_has_award_ref_action = @my_finances.trans_ref_action?
                ui_has_award_ref_void = @my_finances.trans_ref_void?

                it("shows the award date for UID #{uid}") { expect(ui_award_date).to eql(fin_api.formatted_date fin_api.trans_date(award)) }
                it("shows the award description for UID #{uid}") { expect(ui_award_desc).to eql(fin_api.trans_desc(award)) }
                it("shows the award amount for UID #{uid}") { expect(ui_award_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(award)) }
                it("shows the award transaction ID for UID #{uid}") { expect(ui_award_id).to eql("Transaction #: #{fin_api.trans_id(award)}") }
                it("shows no award due date for UID #{uid}") { expect(ui_award_has_due_date).to be false }
                it("shows the award department for UID #{uid}") { expect(ui_award_dept).to include("Department: #{fin_api.trans_dept(award)}") }
                it("shows the award term for UID #{uid}") { expect(ui_award_term).to eql("Term: #{fin_api.trans_term(award)}") }
                if fin_api.trans_status(award) == 'Unapplied'
                  has_unapplied_award = true
                  it("shows the unapplied award text for UID #{uid}") { expect(ui_award_has_unapplied).to be true }
                else
                  it("shows no unapplied award text for UID #{uid}") { expect(ui_award_has_unapplied).to be false }
                end
                it("shows no award potential disbursement date for UID #{uid}") { expect(ui_award_has_disburse).to be false }
                it("shows no award refund method for UID #{uid}") { expect(ui_has_award_ref_method).to be false }
                it("shows no award refund date for UID #{uid}") { expect(ui_has_award_ref_date).to be false }
                it("shows no award refund action for UID #{uid}") { expect(ui_has_award_ref_action).to be false }
                it("shows no award refund void date for UID #{uid}") { expect(ui_has_award_ref_void).to be false }

              else
                logger.warn "Found more than one award on #{award_date}, skipping"
              end
            end

            charges = fin_api.transactions_by_type(fin_api.all_transactions, 'Charge')
            charge_count = charges.length
            logger.info "There are #{charge_count} charges"
            if charges.any?
              charge = charges.first
              charge_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(charge)

              logger.debug "Checking charge on #{charge_date}"

              @my_finances.search('Date Range', nil, charge_date, charge_date, fin_api.trans_id(charge))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail

                ui_charge_date = @my_finances.trans_date
                ui_charge_desc = @my_finances.trans_desc
                ui_charge_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_charge_due_future = @my_finances.trans_due_future_icon_element.visible?
                ui_charge_due_now = @my_finances.trans_due_now_icon_element.visible?
                ui_charge_due_past = @my_finances.trans_due_past_icon_element.visible?

                ui_charge_id = @my_finances.trans_id
                ui_charge_due_date = @my_finances.trans_due_date
                ui_charge_dept = @my_finances.trans_dept
                ui_charge_term = @my_finances.trans_term
                ui_has_charge_disburse = @my_finances.trans_disburse_date?
                ui_has_charge_ref_method = @my_finances.trans_ref_method?
                ui_has_charge_ref_date = @my_finances.trans_ref_date?
                ui_has_charge_ref_action = @my_finances.trans_ref_action?
                ui_has_charge_ref_void = @my_finances.trans_ref_void?

                it("shows the charge date for UID #{uid}") { expect(ui_charge_date).to eql(fin_api.formatted_date fin_api.trans_date(charge)) }
                it("shows the charge description for UID #{uid}") { expect(ui_charge_desc).to eql(fin_api.trans_desc(charge)) }
                it("shows the charge transaction ID for UID #{uid}") { expect(ui_charge_id).to eql("Transaction #: #{fin_api.trans_id(charge)}") }
                it("shows the charge due date for UID #{uid}") { expect(ui_charge_due_date).to eql("Due Date: #{fin_api.formatted_date fin_api.trans_due_date(charge)}") }
                it("shows the charge department URL for UID #{uid}") { expect(ui_charge_dept).to include("Department: #{fin_api.trans_dept(charge)}") }
                it("shows the charge term for UID #{uid}") { expect(ui_charge_term).to eql("Term: #{fin_api.trans_term(charge)}") }
                it("shows no charge potential disbursement date for UID #{uid}") { expect(ui_has_charge_disburse).to be false }
                it("shows no charge refund method for UID #{uid}") { expect(ui_has_charge_ref_method).to be false }
                it("shows no charge refund date for UID #{uid}") { expect(ui_has_charge_ref_date).to be false }
                it("shows no charge refund action for UID #{uid}") { expect(ui_has_charge_ref_action).to be false }
                it("shows no charge refund void date for UID #{uid}") { expect(ui_has_charge_ref_void).to be false }

                # Charges can be partially paid, so only the balance due on the charge will be shown
                if fin_api.trans_status(charge) == 'Installment' ||
                    (fin_api.trans_balance(charge) > 0 && (fin_api.trans_balance(charge) != fin_api.trans_amt(charge)))
                  has_partial_payment = true
                  my_finances_orig_amt = @my_finances.trans_orig_amt.delete('$, ')
                  it("shows the charge balance as the charge amount for UID #{uid}") { expect(ui_charge_amt).to eql(fin_api.amt_to_s fin_api.trans_balance(charge)) }
                  it("shows the charge amount as the original amount for UID #{uid}") { expect(my_finances_orig_amt).to include("OriginalAmount:#{fin_api.amt_to_s fin_api.trans_amt(charge)}") }
                else
                  it("shows the charge amount for UID #{uid}") { expect(ui_charge_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(charge)) }
                end

                # Different charge statuses have different due date icons
                case fin_api.trans_status charge
                  when 'Past due'
                    it("shows a past due charge icon for UID #{uid}") { expect(ui_charge_due_past).to be true }
                  when 'Current'
                    it("shows a charge due now icon for UID #{uid}") { expect(ui_charge_due_now).to be true }
                  when 'Future'
                    it("shows a charge due in the future icon for UID #{uid}") { expect(ui_charge_due_future).to be true }
                  when 'Closed'
                    it "shows no charge due date icon for UID #{uid}" do
                      expect(ui_charge_due_past).to be false
                      expect(ui_charge_due_now).to be false
                      expect(ui_charge_due_future).to be false
                    end
                  else
                    logger.warn "Charge #{fin_api.trans_id(charge)} on #{fin_api.formatted_date fin_api.trans_date(charge)} has an unexpected status"
                end
              else
                logger.warn "Found more than one charge on #{charge_date}, skipping"
              end
            end

            payments = fin_api.transactions_by_type(fin_api.all_transactions, 'Payment')
            payment_count = payments.length
            logger.info "There are #{payment_count} payments"
            if payments.any?
              payment = payments.first
              payment_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(payment)

              logger.debug "Checking payment on #{payment_date}"

              @my_finances.search('Date Range', nil, payment_date, payment_date, fin_api.trans_id(payment))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail

                ui_payment_date = @my_finances.trans_date
                ui_payment_desc = @my_finances.trans_desc
                ui_payment_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_payment_id = @my_finances.trans_id
                ui_payment_due_date = @my_finances.trans_due_date?
                ui_payment_has_dept = @my_finances.trans_dept?
                ui_payment_term = @my_finances.trans_term
                ui_has_payment_disburse = @my_finances.trans_disburse_date?
                ui_has_payment_ref_method = @my_finances.trans_ref_method?
                ui_has_payment_ref_date = @my_finances.trans_ref_date?
                ui_has_payment_ref_action = @my_finances.trans_ref_action?
                ui_has_payment_ref_void = @my_finances.trans_ref_void?

                it("shows the payment date for UID #{uid}") { expect(ui_payment_date).to eql(fin_api.formatted_date fin_api.trans_date(payment)) }
                it("shows the payment description for UID #{uid}") { expect(ui_payment_desc).to eql(fin_api.trans_desc(payment)) }
                it("shows the payment amount for UID #{uid}") { expect(ui_payment_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(payment)) }
                it("shows the payment transaction ID for UID #{uid}") { expect(ui_payment_id).to eql("Transaction #: #{fin_api.trans_id(payment)}") }
                it("shows the payment term for UID #{uid}") { expect(ui_payment_term).to eql("Term: #{fin_api.trans_term(payment)}") }
                it("shows no payment due date for UID #{uid}") { expect(ui_payment_due_date).to be false }
                it("shows no payment refund method for UID #{uid}") { expect(ui_has_payment_ref_method).to be false }
                it("shows no payment refund date for UID #{uid}") { expect(ui_has_payment_ref_date).to be false }
                it("shows no payment refund action for UID #{uid}") { expect(ui_has_payment_ref_action).to be false }
                it("shows no payment refund void date for UID #{uid}") { expect(ui_has_payment_ref_void).to be false }

                if fin_api.trans_dept(payment).blank?
                  it("shows no payment department for UID #{uid}") { expect(ui_payment_has_dept).to be false }
                else
                  ui_payment_dept = @my_finances.trans_dept
                  it("shows the payment department for UID #{uid}") { expect(ui_payment_dept).to include("Department: #{fin_api.trans_dept(payment)}") }
                end
                if fin_api.trans_disburse_date(payment).nil?
                  it("shows no payment potential disbursement date for UID #{uid}") { expect(ui_has_payment_disburse).to be false }
                else
                  has_potential_disburse = true
                  ui_payment_disburse = @my_finances.trans_disburse_date
                  it("shows the payment potential disbursement date for UID #{uid}") { expect(ui_payment_disburse).to eql("Potential Disbursement Date: #{fin_api.trans_disburse_date(payment)}") }
                end
              else
                logger.warn "Found more than one payment on #{payment_date}, skipping"
              end
            end

            refunds = fin_api.transactions_by_type(fin_api.all_transactions, 'Refund')
            refund_count = refunds.length
            logger.info "There are #{refund_count} refunds"
            if refunds.any?
              refund = refunds.first
              refund_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(refund)

              logger.debug "Checking refund on #{refund_date}"

              @my_finances.search('Date Range', nil, refund_date, refund_date, fin_api.trans_id(refund))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail
                ui_ref_date = @my_finances.trans_date
                ui_ref_desc = @my_finances.trans_desc
                ui_ref_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_ref_id = @my_finances.trans_id
                ui_ref_due_date = @my_finances.trans_due_date?
                ui_ref_dept = @my_finances.trans_dept
                ui_ref_term = @my_finances.trans_term
                ui_has_ref_disburse = @my_finances.trans_disburse_date?
                ui_has_ref_method = @my_finances.trans_ref_method?
                ui_has_ref_date = @my_finances.trans_ref_date?
                ui_has_ref_action = @my_finances.trans_ref_action?
                ui_has_ref_void = @my_finances.trans_ref_void?

                it("shows the refund date for UID #{uid}") { expect(ui_ref_date).to eql(fin_api.formatted_date fin_api.trans_date(refund)) }
                it("shows the refund description for UID #{uid}") { expect(ui_ref_desc).to eql(fin_api.trans_desc(refund)) }
                it("shows the refund amount for UID #{uid}") { expect(ui_ref_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(refund)) }
                it("shows the refund transaction ID for UID #{uid}") { expect(ui_ref_id).to eql("Transaction #: #{fin_api.trans_id(refund)}") }
                it("shows the refund department URL for UID #{uid}") { expect(ui_ref_dept).to include("Department: #{fin_api.trans_dept(refund)}") }
                it("shows the refund term for UID #{uid}") { expect(ui_ref_term).to eql("Term: #{fin_api.trans_term(refund)}") }
                it("shows no refund due date for UID #{uid}") { expect(ui_ref_due_date).to be false }
                it("shows no potential disbursement date for UID #{uid}") { expect(ui_has_ref_disburse).to be false }

                if fin_api.trans_refund_method(refund).blank?
                  it("shows no refund payment method for UID #{uid}") { expect(ui_has_ref_method).to be false }
                else
                  ui_refund_method = @my_finances.trans_ref_method
                  it("shows the refund payment method for UID #{uid}") { expect(ui_refund_method).to eql("Payment Method: #{fin_api.trans_refund_method(refund)}") }
                end

                if fin_api.trans_refund_last_action_date(refund).blank?
                  it("shows no refund action date for UID #{uid}") { expect(ui_has_ref_date).to be false }
                else
                  ui_ref_action_date = @my_finances.trans_ref_date
                  it("shows the refund action date for UID #{uid}") { expect(ui_ref_action_date).to eql ("Action Date: #{fin_api.formatted_date fin_api.trans_refund_last_action_date(refund)}") }
                end

                if fin_api.trans_refund_last_action(refund).blank?
                  it("shows no refund action for UID #{uid}") { expect(ui_has_ref_action).to be false }
                else
                  ui_refund_action = @my_finances.trans_ref_action
                  it("shows the refund action for UID #{uid}") { expect(ui_refund_action).to eql("Action: #{fin_api.trans_refund_last_action(refund)}") }
                end

                if fin_api.trans_refund_void_date(refund).blank?
                  it("shows no refund void date for UID #{uid}") { expect(ui_has_ref_void).to be false }
                else
                  ui_refund_void = @my_finances.trans_ref_void
                  it("shows the refund void date for UID #{uid}") { expect(ui_refund_void).to eql("Date Voided: #{fin_api.formatted_date fin_api.trans_refund_void_date(refund)}") }
                end
              else
                logger.warn "Found more than one refund on #{refund_date}, skipping"
              end
            end

            waivers = fin_api.transactions_by_type(fin_api.all_transactions, 'Waiver')
            waiver_count = waivers.length
            logger.info "There are #{waiver_count} waivers"
            if waivers.any?
              waiver = waivers.first
              waiver_date = WebDriverUtils.ui_date_input_format fin_api.trans_date_as_date(waiver)

              logger.debug "Checking waiver on #{waiver_date}"

              @my_finances.search('Date Range', nil, waiver_date, waiver_date, fin_api.trans_id(waiver))
              if @my_finances.visible_transaction_count == 1
                @my_finances.toggle_first_trans_detail
                ui_waiver_date = @my_finances.trans_date
                ui_waiver_desc = @my_finances.trans_desc
                ui_waiver_amt = @my_finances.strip_currency @my_finances.trans_amt
                ui_waiver_id = @my_finances.trans_id
                ui_waiver_due_date = @my_finances.trans_due_date?
                ui_waiver_dept = @my_finances.trans_dept
                ui_waiver_term = @my_finances.trans_term
                ui_waiver_has_disburse = @my_finances.trans_disburse_date?
                ui_waiver_has_ref_method = @my_finances.trans_ref_method?
                ui_waiver_has_ref_date = @my_finances.trans_ref_date?
                ui_waiver_has_ref_action = @my_finances.trans_ref_action?
                ui_waiver_has_ref_void = @my_finances.trans_ref_void?

                it("shows the waiver date date for UID #{uid}") { expect(ui_waiver_date).to eql(Time.parse(fin_api.trans_date(waiver)).strftime('%m/%d/%y')) }
                it("shows the waiver description for UID #{uid}") { expect(ui_waiver_desc).to eql(fin_api.trans_desc(waiver)) }
                it("shows the waiver amount for UID #{uid}") { expect(ui_waiver_amt).to eql(fin_api.amt_to_s fin_api.trans_amt(waiver)) }
                it("shows the waiver transaction ID for UID #{uid}") { expect(ui_waiver_id).to eql("Transaction #: #{fin_api.trans_id(waiver)}") }
                it("shows no waiver due date for UID #{uid}") { expect(ui_waiver_due_date).to be false }
                it("shows the waiver department URL for UID #{uid}") { expect(ui_waiver_dept).to include("Department: #{fin_api.trans_dept(waiver)}") }
                it("shows the waiver term for UID #{uid}") { expect(ui_waiver_term).to eql("Term: #{fin_api.trans_term(waiver)}") }
                it("shows no waiver potential disbursement date for UID #{uid}") { expect(ui_waiver_has_disburse).to be false }
                it("shows no waiver refund method for UID #{uid}") { expect(ui_waiver_has_ref_method).to be false }
                it("shows no waiver refund action date for UID #{uid}") { expect(ui_waiver_has_ref_date).to be false }
                it("shows no waiver refund action for UID #{uid}") { expect(ui_waiver_has_ref_action).to be false }
                it("shows no waiver refund void for UID #{uid}") { expect(ui_waiver_has_ref_void).to be false }
              else
                logger.warn "Found more than one waiver on #{waiver_date}, skipping"
              end
            end

            # STATUS POPOVER

            if @status_api.is_student? || @status_api.is_ex_student?

              @my_finances.open_profile_popover

              has_amt_due_alert = WebDriverUtils.verify_block { @my_finances.amount_due_status_alert_element.when_visible WebDriverUtils.page_event_timeout }
              popover_amt_due = @my_finances.alert_amt_due if has_amt_due_alert

              # Popover alert will combine amounts from legacy and CS
              legacy_amt_due_now = fin_api.min_amt_due.nil? ? 0 : BigDecimal(fin_api.amt_to_s fin_api.min_amt_due)
              cs_amt_due_now = fin_cs_api.amount_due_now.nil? ? 0 : BigDecimal(fin_cs_api.amt_to_s fin_cs_api.amount_due_now)
              ttl_due_now = legacy_amt_due_now + cs_amt_due_now

              if ttl_due_now > 0
                it("shows an Amount Due alert for UID #{uid}") { expect(has_amt_due_alert).to be true }
                if has_amt_due_alert
                  it("shows the amount due on the Amount Due alert for UID #{uid}") { expect(popover_amt_due).to eql(fin_api.amt_to_s ttl_due_now) }
                end
              else
                it("shows no Amount Due alert for UID #{uid}") { expect(has_amt_due_alert).to be false }
              end

              if has_amt_due_alert
                @dashboard_page.load_page
                @dashboard_page.open_profile_popover
                @dashboard_page.click_amt_due_alert

                amt_due_link_works = (@my_finances.current_url == "#{WebDriverUtils.base_url}/finances")

                it("offers a link from the profile popover amount due alert to the My Finances page for UID #{uid}") { expect(amt_due_link_works).to be true }
              end
            end

          else
            it("shows a no-data message for UID #{uid}") { expect(my_fin_no_cars_msg).to be true }
          end

        rescue => e
          logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
        ensure
          test_output_row = [uid, has_finances_tab, has_cars_data, acct_bal, amt_due_now, has_past_due_amt, has_future_activity,
                             is_dpp, has_dpp_balance, is_dpp_past_due, adjustment_count, award_count, charge_count, payment_count,
                             refund_count, waiver_count, has_unapplied_award, has_partial_payment, has_potential_disburse]
          UserUtils.add_csv_row(test_output, test_output_row)
        end
      end

      it 'has CARS data for at least one of the test UIDs' do
        expect(testable_users.any?).to be true
      end

    rescue => e
      logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
