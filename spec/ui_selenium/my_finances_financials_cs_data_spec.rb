describe 'My Finances Campus Solutions student financials', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer == 'local'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser

      test_users = UserUtils.load_test_users.select { |user| user['financesData'] }
      testable_users = []
      test_output_heading = ['UID', 'Finances Tab', 'Acct Bal', 'Amt Due Now', 'Past Due', 'Future Activity',
                             'Charges', 'Payments', 'Awards', 'Has Partial Payment']
      test_output = UserUtils.initialize_output_csv(self, test_output_heading)

      @splash_page = CalCentralPages::SplashPage.new driver
      @status_api = ApiMyStatusPage.new driver
      @my_finances_landing = CalCentralPages::MyFinancesPages::MyFinancesLandingPage.new driver
      @my_finances_billing = CalCentralPages::MyFinancesPages::MyFinancesBillingPage.new driver
      @dashboard_page = CalCentralPages::MyDashboardPage.new driver

      test_users.each do |user|
        uid = user['uid']
        logger.info "UID is #{uid}"

        has_finances_tab = false
        acct_bal = nil
        amt_due_now = nil
        has_past_due_amt = false
        has_future_activity = false
        charge_count = nil
        payment_count = nil
        awards_count = nil
        has_partial_payment = false

        begin
          @splash_page.load_page
          @splash_page.basic_auth uid
          @status_api.get_json driver

          # Get data from billing API
          fin_api = ApiCSBillingPage.new driver
          fin_api.get_json driver

          if (has_finances_tab = @status_api.has_finances_tab?)

            if fin_api.error?

              @my_finances_landing.load_page

              shows_error_msg = WebDriverUtils.verify_block { @my_finances_billing.error_msg_element.when_visible WebDriverUtils.page_load_timeout }
              it("shows an 'unavailable' message for UID #{uid}") { expect(shows_error_msg).to be true }

            elsif fin_api.feed.empty?

              @my_finances_billing.load_summary

              shows_no_data_msg = WebDriverUtils.verify_block { @my_finances_billing.no_cs_data_msg_element.when_visible WebDriverUtils.page_load_timeout }
              it("shows a no-data message for UID #{uid}") { expect(shows_no_data_msg).to be true }

            elsif fin_api.activity.empty?

              @my_finances_billing.load_summary

              acct_bal = 'Zero'
              my_fin_amt_due_now = @my_finances_billing.amt_due_now_cs
              it("shows a zero amount due now for UID #{uid}") { expect(my_fin_amt_due_now).to eql('0') }

              my_fin_future_activity = @my_finances_billing.charges_not_due_cs
              it("shows a zero amount due in the future for UID #{uid}") { expect(my_fin_future_activity).to eql('0') }

            else

              testable_users << uid

              # ACCOUNT SUMMARY CARD

              @my_finances_billing.load_summary

              # Balance

              my_fin_acct_bal = @my_finances_billing.account_balance_cs
              it("shows the right account balance for UID #{uid}") { expect(my_fin_acct_bal).to eql(WebDriverUtils.amt_to_s fin_api.account_balance) }

              if fin_api.account_balance > 0
                acct_bal = 'Positive'
                @my_finances_billing.transaction_table_element.when_visible
                my_fin_balance_transactions = @my_finances_billing.visible_transactions_sum_str
                it("shows the open charges for UID #{uid}") { expect(my_fin_balance_transactions).to eql(WebDriverUtils.amt_to_s fin_api.transactions_sum(fin_api.open_charges)) }

              elsif fin_api.account_balance == 0
                acct_bal = 'Zero'
              elsif fin_api.account_balance < 0
                acct_bal = 'Negative'
              else
                it("shows a non-numeric account balance for UID #{uid}") { fail }
              end

              # Amount due now

              my_fin_amt_due_now = @my_finances_billing.amt_due_now_cs
              it("shows the right amount due now for UID #{uid}") { expect(my_fin_amt_due_now).to eql(WebDriverUtils.amt_to_s fin_api.amount_due_now) }

              my_fin_amt_due_label = @my_finances_billing.amt_due_now_label_cs

              if fin_api.amount_due_now > 0
                amt_due_now = 'Positive'
                it("shows the label Amount Due Now for UID #{uid}") { expect(my_fin_amt_due_label).to include('Amount Due Now') }

              elsif fin_api.amount_due_now == 0
                amt_due_now = 'Zero'
                it("shows the label Amount Due Now for UID #{uid}") { expect(my_fin_amt_due_label).to include('Amount Due Now') }

              elsif fin_api.amount_due_now < 0
                amt_due_now = 'Negative'
                it("shows the label Credit Balance for UID #{uid}") { expect(my_fin_amt_due_label).to include('Credit Balance') }

              else
                it("shows a non-numeric minimum amount due for UID #{uid}") { fail }
              end

              # TODO - past due amount

              # Charges not yet due

              if fin_api.charges_not_yet_due > 0
                has_future_activity = true
                my_fin_future_activity = @my_finances_billing.charges_not_due_cs
                it("shows the charges not yet due for UID #{uid}") { expect(my_fin_future_activity).to eql(WebDriverUtils.amt_to_s fin_api.charges_not_yet_due) }
              end

              # Make payment link

              my_fin_pmt_link = @my_finances_billing.make_payment_link_cs?
              fin_api.account_balance.zero? ?
                  it("shows no make payment link for UID #{uid}") { expect(my_fin_pmt_link).to be false } :
                  it("shows a make payment link for UID #{uid}") { expect(my_fin_pmt_link).to be true } unless fin_api.account_balance.zero?

              # TODO - status popover

              # TRANSACTION DETAIL CARD

              if fin_api.activity.any?

                @my_finances_billing.search('All Transactions', nil, '', '', '')
                @my_finances_billing.show_all

                transactions_count_in_ui = @my_finances_billing.visible_transaction_count
                it("shows all the transactions for UID #{uid}") { expect(transactions_count_in_ui).to eql(fin_api.activity.length) }

                @my_finances_billing.search('Balance', nil, '', '', '')
                @my_finances_billing.show_all
                ui_open_trans = @my_finances_billing.visible_transaction_count

                it "shows 'Unpaid' and non-zero balance transactions on the Balance filter for UID #{uid}" do
                  expect(ui_open_trans).to eql(fin_api.balance_transactions.length)
                end

                # Charges
                charges = fin_api.transactions_by_type(fin_api.activity, 'Charge')
                charge_count = charges.length
                logger.info "There are #{charge_count} charges"
                if charges.any?
                  charge = charges.last
                  charge_date = WebDriverUtils.ui_date_input_format fin_api.effective_date_as_date(charge)

                  logger.debug "Checking charge on #{charge_date} with desc '#{fin_api.description(charge)}'"

                  @my_finances_billing.search('Date Range', nil, charge_date, charge_date, fin_api.description(charge))
                  if @my_finances_billing.visible_transaction_count == 1
                    @my_finances_billing.toggle_first_trans_detail

                    ui_charge_date = @my_finances_billing.item_date
                    it("shows the charge date for UID #{uid}") { expect(ui_charge_date).to eql(fin_api.formatted_date fin_api.effective_date(charge)) }

                    ui_charge_desc = @my_finances_billing.item_desc
                    it("shows the charge description for UID #{uid}") { expect(ui_charge_desc).to eql(fin_api.description(charge)) }

                    ui_charge_amt = @my_finances_billing.strip_currency @my_finances_billing.item_amt
                    it("shows the charge amount for UID #{uid}") { expect(ui_charge_amt).to eql(WebDriverUtils.amt_to_s fin_api.line_amount(charge)) }

                    ui_charge_type = @my_finances_billing.item_type
                    it("shows the transaction type of the charge for UID #{uid}") { expect(ui_charge_type).to eql(fin_api.type charge) }

                    if fin_api.status(charge) == 'Paid' || fin_api.due_date(charge).nil?
                      ui_charge_due_date = @my_finances_billing.item_due_date?
                      it("shows no paid charge due date for UID #{uid}") { expect(ui_charge_due_date).to be false }
                    else
                      ui_charge_due_date = @my_finances_billing.item_due_date
                      it("shows the unpaid charge due date for UID #{uid}") { expect(ui_charge_due_date).to eql(fin_api.formatted_date fin_api.due_date(charge)) }
                    end

                    ui_charge_due_future = @my_finances_billing.item_due_future_icon_element.visible?
                    ui_charge_due_now = @my_finances_billing.item_due_now_icon_element.visible?
                    ui_charge_due_past = @my_finances_billing.item_due_past_icon_element.visible?
                    case fin_api.due_flag charge
                      when 'OVER_DUE'
                        it("shows a past due charge icon for UID #{uid}") { expect(ui_charge_due_past).to be true }
                      when 'DUE_NOW'
                        it("shows a charge due now icon for UID #{uid}") { expect(ui_charge_due_now).to be true }
                      when 'FUTURE_DUE'
                        it("shows a charge due in the future icon for UID #{uid}") { expect(ui_charge_due_future).to be true }
                      when nil
                        it "shows no charge due date icon for UID #{uid}" do
                          expect(ui_charge_due_past).to be false
                          expect(ui_charge_due_now).to be false
                          expect(ui_charge_due_future).to be false
                        end
                      else
                        logger.warn "Charge #{fin_api.description(charge)} on #{fin_api.formatted_date fin_api.effective_date(charge)} has an unexpected status"
                    end

                    # Detail

                    ui_charge_status = @my_finances_billing.item_detail_status
                    it("shows the charge status in the charge detail for UID #{uid}") { expect(ui_charge_status).to eql(fin_api.status charge) }

                    ui_charge_term = @my_finances_billing.item_detail_term
                    it("shows the charge term for UID #{uid}") { expect(ui_charge_term).to eql("#{fin_api.term_desc(charge)}") }

                    ui_charge_detail_type = @my_finances_billing.item_detail_type
                    it("shows the transaction type on the charge detail view for UID #{uid}") { expect(ui_charge_detail_type).to eql(fin_api.type charge) }

                    ui_charge_has_orig_amt = @my_finances_billing.item_detail_orig_amt?
                    it("shows no original amount in the charge detail for UID #{uid}") { expect(ui_charge_has_orig_amt).to be false }

                    @my_finances_billing.search('Balance', nil, nil, nil, fin_api.description(charge))

                    if fin_api.balance(charge) == 0

                      ui_balance_empty = @my_finances_billing.visible_transaction_count.zero?
                      it("shows no paid charges on the balance filter for UID #{uid}") { expect(ui_balance_empty).to be true }

                    else

                      if @my_finances_billing.visible_transaction_count == 2

                        ui_balance_has_orig_amt = @my_finances_billing.item_detail_orig_amt?
                        it("shows the original amount in the charge detail for UID #{uid}") { expect(ui_balance_has_orig_amt).to be true }

                        ui_charge_orig_amt = @my_finances_billing.strip_currency @my_finances_billing.item_detail_orig_amt
                        it("shows the right original amount in the charge detail for UID #{uid}") { expect(ui_charge_orig_amt).to eql(WebDriverUtils.amt_to_s fin_api.line_amount(charge)) }

                        has_partial_payment = true if (fin_api.balance(charge) != fin_api.line_amount(charge))

                      else
                        logger.warn 'Found more than one charge with the same description on the balance tab, skipping'
                      end

                    end

                  else
                    logger.warn "Found more than one charge with the same description on #{charge_date}, skipping"
                  end
                end

                # Payments
                payments = fin_api.transactions_by_type(fin_api.activity, 'Payment')
                payment_count = payments.length
                logger.info "There are #{payment_count} payments"
                if payments.any?
                  payment = payments.last
                  payment_date = WebDriverUtils.ui_date_input_format fin_api.effective_date_as_date(payment)

                  logger.debug "Checking payment on #{payment_date}"

                  @my_finances_billing.search('Date Range', nil, payment_date, payment_date, fin_api.description(payment))
                  if @my_finances_billing.visible_transaction_count == 1
                    @my_finances_billing.toggle_first_trans_detail

                    ui_payment_date = @my_finances_billing.item_date
                    it("shows the payment date for UID #{uid}") { expect(ui_payment_date).to eql(fin_api.formatted_date fin_api.effective_date(payment)) }

                    ui_payment_desc = @my_finances_billing.item_desc
                    it("shows the payment description for UID #{uid}") { expect(ui_payment_desc).to eql(fin_api.description(payment)) }

                    ui_payment_amt = @my_finances_billing.strip_currency @my_finances_billing.item_amt
                    it("shows the payment amount for UID #{uid}") { expect(ui_payment_amt).to eql(WebDriverUtils.amt_to_s fin_api.line_amount(payment)) }

                    ui_payment_type = @my_finances_billing.item_type
                    it("shows the transaction type of the payment for UID #{uid}") { expect(ui_payment_type).to eql(fin_api.type payment) }

                    ui_payment_due_date = @my_finances_billing.item_due_date?
                    it("shows no payment due date for UID #{uid}") { expect(ui_payment_due_date).to be false }

                    # Detail

                    ui_payment_has_status = @my_finances_billing.item_detail_status?
                    it("shows no payment status for UID #{uid}") { expect(ui_payment_has_status).to be false }

                    ui_payment_has_orig_amt = @my_finances_billing.item_detail_orig_amt?
                    it("shows no payment original amount for UID #{uid}") { expect(ui_payment_has_orig_amt).to be false }

                    ui_payment_term = @my_finances_billing.item_detail_term
                    it("shows the payment term for UID #{uid}") { expect(ui_payment_term).to eql(fin_api.term_desc(payment)) }

                    ui_payment_detail_type = @my_finances_billing.item_detail_type
                    it("shows the transaction type in the payment detail view for UID #{uid}") { expect(ui_payment_detail_type).to eql(fin_api.type payment) }

                  else
                    logger.warn "Found more than one payment with the same description on #{payment_date}, skipping"
                  end
                end
              end

              # Financial Aid
              awards = fin_api.transactions_by_type(fin_api.activity, 'Financial Aid')
              awards_count = awards.length
              logger.info "There are #{awards_count} awards"
              if awards.any?
                award = awards.last
                award_date = WebDriverUtils.ui_date_input_format fin_api.effective_date_as_date(award)

                logger.debug "Checking award on #{award_date}"

                @my_finances_billing.search('Date Range', nil, award_date, award_date, fin_api.description(award))
                if @my_finances_billing.visible_transaction_count == 1
                  @my_finances_billing.toggle_first_trans_detail

                  ui_award_date = @my_finances_billing.item_date
                  it("shows the award date for UID #{uid}") { expect(ui_award_date).to eql(fin_api.formatted_date fin_api.effective_date(award)) }

                  ui_award_desc = @my_finances_billing.item_desc
                  it("shows the award description for UID #{uid}") { expect(ui_award_desc).to eql(fin_api.description(award)) }

                  ui_award_amt = @my_finances_billing.strip_currency @my_finances_billing.item_amt
                  it("shows the award amount for UID #{uid}") { expect(ui_award_amt).to eql(WebDriverUtils.amt_to_s fin_api.line_amount(award)) }

                  ui_award_type = @my_finances_billing.item_type
                  it("shows the transaction type of the award for UID #{uid}") { expect(ui_award_type).to eql(fin_api.type award) }

                  ui_award_due_date = @my_finances_billing.item_due_date?
                  it("shows no award due date for UID #{uid}") { expect(ui_award_due_date).to be false }

                  # Detail

                  ui_award_has_status = @my_finances_billing.item_detail_status?
                  it("shows no award status for UID #{uid}") { expect(ui_award_has_status).to be false }

                  ui_award_has_orig_amt = @my_finances_billing.item_detail_orig_amt?
                  it("shows no award original amount for UID #{uid}") { expect(ui_award_has_orig_amt).to be false }

                  ui_award_term = @my_finances_billing.item_detail_term
                  it("shows the award term for UID #{uid}") { expect(ui_award_term).to eql(fin_api.term_desc(award)) }

                  ui_award_detail_type = @my_finances_billing.item_detail_type
                  it("shows the transaction type in the award detail view for UID #{uid}") { expect(ui_award_detail_type).to eql(fin_api.type award) }

                else
                  logger.warn "Found more than one award with the same description on #{award_date}, skipping"
                end
              end

            # TODO - other transaction types (deposits, refunds)

            end
          end

        rescue => e
          logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
        ensure
          test_output_row = [uid, has_finances_tab, acct_bal, amt_due_now, has_past_due_amt, has_future_activity,
                             charge_count, payment_count, awards_count, has_partial_payment]
          UserUtils.add_csv_row(test_output, test_output_row)
        end
      end

      it 'has financial data for at least one of the test UIDs' do
        expect(testable_users.any?).to be true
      end

    rescue => e
      logger.error "#{e.message + "\n"} #{e.backtrace.join("\n ")}"
    ensure
      WebDriverUtils.quit_browser driver
    end
  end
end
