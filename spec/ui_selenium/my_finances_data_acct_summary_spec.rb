describe 'My Finances Billing Summary', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    include ClassLogger

    begin
      driver = WebDriverUtils.launch_browser
      test_output = UserUtils.initialize_output_csv(self)
      test_users = UserUtils.load_test_users
      testable_users = []

      CSV.open(test_output, 'wb') do |user_info_csv|
        user_info_csv << ['UID', 'Finances Tab', 'CARS Data', 'Acct Bal', 'Amt Due Now', 'Past Due', 'Future Activity',
                          'On DPP', 'Norm Install', 'DPP Past Due', 'Error?']
      end

      test_users.each do |user|
        if user['finances']
          uid = user['uid'].to_s
          logger.info('UID is ' + uid)
          has_finances_tab = false
          has_cars_data = false
          acct_bal = false
          amt_due_now = false
          has_past_due_amt = false
          has_future_activity = false
          is_dpp = false
          has_dpp_balance = false
          is_dpp_past_due = false
          threw_error = false

          begin
            splash_page = CalCentralPages::SplashPage.new(driver)
            splash_page.load_page
            splash_page.basic_auth uid
            status_api_page = ApiMyStatusPage.new(driver)
            status_api_page.get_json(driver)
            has_finances_tab = status_api_page.has_finances_tab?
            fin_api_page = ApiMyFinancialsPage.new(driver)
            fin_api_page.get_json(driver)
            my_finances_page = CalCentralPages::MyFinancesPages::MyFinancesDetailsPage.new(driver)
            my_finances_page.load_page
            my_finances_page.billing_summary_spinner_element.when_not_visible(timeout=WebDriverUtils.page_load_timeout)

            my_fin_no_cars_msg = my_finances_page.no_cars_data_msg?

            if fin_api_page.has_cars_data?
              testable_users.push(uid)
              has_cars_data = true
              it "does not show a no-data message for UID #{uid}" do
                expect(my_fin_no_cars_msg).to be false
              end

              # ACCOUNT BALANCE
              my_fin_acct_bal = my_finances_page.account_balance
              my_fin_zero_bal_text = my_finances_page.zero_balance_text?
              my_fin_credit_bal_text = my_finances_page.credit_balance_text?
              if fin_api_page.account_balance > 0
                acct_bal = 'Positive'
                my_fin_balance_transactions = my_finances_page.visible_transactions_sum_str
                it "shows the open charges for UID #{uid}" do
                  expect(my_fin_balance_transactions).to eql(fin_api_page.open_charges_sum_str)
                end
              elsif fin_api_page.account_balance == 0
                acct_bal = 'Zero'
                # Expect 'zero balance' message, but infrequent ODSQA refresh can leave balance and transactions out of sync, causing intermittent test failures
              elsif fin_api_page.account_balance < 0
                acct_bal = 'Negative'
                # Expect 'credit balance' message, but infrequent ODSQA refresh can leave balance and transactions out of sync, causing intermittent test failures
              end
              it "shows the right account balance for UID #{uid}" do
                expect(my_fin_acct_bal).to eql(fin_api_page.account_balance_str)
              end

              # AMOUNT DUE NOW
              my_fin_amt_due_label = my_finances_page.amt_due_now_label
              if fin_api_page.min_amt_due > 0
                amt_due_now = 'Positive'
                it "shows the label Amount Due Now for UID #{uid}" do
                  expect(my_fin_amt_due_label).to include('Amount Due Now')
                end
              elsif fin_api_page.min_amt_due == 0
                amt_due_now = 'Zero'
                it "shows the label Amount Due Now for UID #{uid}" do
                  expect(my_fin_amt_due_label).to include('Amount Due Now')
                end
              elsif fin_api_page.min_amt_due < 0
                amt_due_now = 'Negative'
                it "shows the label Credit Balance for UID #{uid}" do
                  expect(my_fin_amt_due_label).to include('Credit Balance')
                end
              end
              my_fin_amt_due_now = my_finances_page.amt_due_now
              it "shows the right amount due now for UID #{uid}" do
                expect(my_fin_amt_due_now).to eql(fin_api_page.min_amt_due_str)
              end

              # PAST DUE AMOUNT
              if fin_api_page.past_due_amt > 0
                has_past_due_amt = true
                my_fin_past_due_bal = my_finances_page.past_due_amt
                it "shows the past due amount for UID #{uid}" do
                  expect(my_fin_past_due_bal).to eql(fin_api_page.past_due_amt_str)
                end
              end

              # CHARGES NOT YET DUE
              if fin_api_page.future_activity > 0
                has_future_activity = true
                my_fin_future_activity = my_finances_page.charges_not_due
                it "shows the charges not yet due for UID #{uid}" do
                  expect(my_fin_future_activity).to eql(fin_api_page.future_activity_str)
                end
              end

              # MAKE PAYMENT LINK
              my_fin_pmt_link = my_finances_page.make_payment_link?
              if fin_api_page.account_balance != 0
                it "shows make payment link for UID #{uid}" do
                  expect(my_fin_pmt_link).to be true
                end
              end

              # LAST STATEMENT BALANCE
              my_finances_page.show_last_statement_bal
              my_fin_last_bal = my_finances_page.last_statement_balance
              it "shows the right last statement balance for UID #{uid}" do
                expect(my_fin_last_bal).to eql(fin_api_page.last_statement_balance_str)
              end

              # DPP
              my_fin_dpp_bal_element = my_finances_page.dpp_balance_element?
              my_fin_dpp_text = my_finances_page.dpp_text?
              my_fin_dpp_install_element = my_finances_page.dpp_normal_install_element?
              if fin_api_page.is_on_dpp?
                is_dpp = true
                my_fin_dpp_bal = my_finances_page.dpp_balance
                it "shows DPP balance for UID #{uid}" do
                  expect(my_fin_dpp_bal).to eql(fin_api_page.dpp_balance_str)
                end
                it "shows DPP informational text for UID #{uid}" do
                  expect(my_fin_dpp_text).to be true
                end
                if fin_api_page.dpp_balance > 0
                  has_dpp_balance = true
                  my_fin_dpp_install = my_finances_page.dpp_normal_install
                  it "shows DPP normal installment amount for UID #{uid}" do
                    expect(my_fin_dpp_install).to eql(fin_api_page.dpp_norm_install_amt_str)
                  end
                else
                  it "shows no DPP normal installment amount for UID #{uid}" do
                    expect(my_fin_dpp_install_element).to be false
                  end
                end
                if fin_api_page.is_dpp_past_due?
                  is_dpp_past_due = true
                end
              else
                it "shows no DPP balance for UID #{uid}" do
                  expect(my_fin_dpp_bal_element).to be false
                end
                it "shows no DPP informational text for UID #{uid}" do
                  expect(my_fin_dpp_text).to be false
                end
              end

              # ALERT POPOVER
              if status_api_page.is_student? || status_api_page.is_ex_student?
                my_finances_page.open_profile_popover

                has_amt_due_alert = my_finances_page.amount_due_status_alert?
                popover_amt_due = my_finances_page.alert_amt_due if has_amt_due_alert

                if fin_api_page.min_amt_due > 0
                  it "shows an Amount Due alert for UID #{uid}" do
                    expect(has_amt_due_alert).to be true
                  end
                  it "shows the amount due on the Amount Due alert for UID #{uid}" do
                    expect(popover_amt_due).to eql(fin_api_page.min_amt_due_str)
                  end
                else
                  it "shows no Amount Due alert for UID #{uid}" do
                    expect(has_amt_due_alert).to be false
                  end
                end

                if has_amt_due_alert
                  dashboard_page = CalCentralPages::MyDashboardPage.new driver
                  dashboard_page.load_page
                  dashboard_page.open_profile_popover
                  dashboard_page.click_amt_due_alert
                  my_finances_page.billing_summary_list_element.when_present timeout

                  amt_due_link_works = my_finances_page.amt_due_now_element?

                  it "offers a link from the profile popover amount due alert to the My Finances page for UID #{uid}" do
                    expect(amt_due_link_works).to be true
                  end
                end
              end

            else
              it "shows a no-data message for UID #{uid}" do
                expect(my_fin_no_cars_msg).to be true
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n")
            threw_error = true
          ensure
            CSV.open(test_output, 'a+') do |user_info_csv|
              user_info_csv << [uid, has_finances_tab, has_cars_data, acct_bal, amt_due_now, has_past_due_amt, has_future_activity,
                                is_dpp, has_dpp_balance, is_dpp_past_due, threw_error]
            end
          end
        end
      end
      it 'has CARS information for at least one of the test UIDs' do
        expect(testable_users.length).to be > 0
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      WebDriverUtils.quit_browser(driver)
    end
  end
end
