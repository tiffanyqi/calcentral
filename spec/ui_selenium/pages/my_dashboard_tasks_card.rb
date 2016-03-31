module CalCentralPages

  class MyDashboardTasksCard < MyDashboardPage

    include PageObject
    include CalCentralPages
    include ClassLogger

    # TASKS
    button(:completed_tasks_tab, :xpath => '//button[contains(.,"completed")]')
    paragraph(:no_tasks_message, :xpath => '//p[contains(.,"You have no tasks and assignments.")]')
    button(:scheduled_tasks_tab, :xpath => '//button[contains(.,"scheduled")]')
    button(:unsched_tasks_tab, :xpath => '//button[contains(.,"unscheduled")]')
    button(:completed_tasks_tab, :xpath => '//div[@class="cc-widget-tasks-container"]//li[3]/button')

    # ADD/EDIT TASK
    button(:new_task_button, :xpath => '//button[contains(.,"New Task")]')
    text_field(:new_task_title_input, :xpath => '//input[@data-ng-model="addEditTask.title"]')
    text_field(:new_task_date_input, :xpath => '//input[@data-ng-model="addEditTask.dueDate"]')
    text_field(:new_task_notes_input, :xpath => '//textarea[@data-ng-model="addEditTask.notes"]')
    button(:add_new_task_button, :xpath => '//button[contains(.,"Add Task")]')
    button(:cancel_new_task_button, :xpath => '//button[contains(.,"Cancel")]')
    paragraph(:new_task_date_validation_error, :xpath => '//p[@data-ng-show="cc_widget_tasks_form.add_task_due_date.$error.ccDateValidator"]')

    # TASKS: OVERDUE
    span(:overdue_task_count, :xpath => '//span[@data-ng-bind="overdueTasks.length"]')
    elements(:overdue_task, :list_item, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]')
    elements(:overdue_task_toggle, :div, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//span[contains(.,"Show")]/..')
    elements(:overdue_task_edit_button, :button, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//button[contains(.,"Edit")]')
    elements(:overdue_task_delete_button, :button, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//button[contains(.,"Delete")]')
    elements(:overdue_task_save_button, :button, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//button[contains(.,"Save")]')
    elements(:overdue_task_cbx, :checkbox, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//input[@id="cc-widget-tasks-checkbox-0"]')
    elements(:overdue_task_title, :div, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//strong[@data-ng-bind="task.title"]')
    elements(:overdue_task_title_input, :text_field, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//input[@data-ng-model="addEditTask.title"]')
    elements(:overdue_task_course, :span, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//span[@data-ng-bind="task.course_code"]')
    elements(:overdue_task_date, :div, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//div[@class="cc-widget-tasks-col cc-widget-tasks-col-date"]/span')
    elements(:overdue_task_time, :div, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//div[@data-ng-if="task.emitter==\'bCourses\' && task.dueDate.hasTime"]')
    elements(:overdue_task_date_input, :text_field, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//input[@name="add_task_due_date"]')
    elements(:overdue_task_notes_input, :text_field, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//textarea[@data-ng-model="addEditTask.notes"]')
    elements(:overdue_task_bcourses_link, :link, :xpath => '//li[@data-ng-repeat="task in overdueTasks | limitTo: overdueLimit"]//a[contains(.,"View in bCourses")]')
    button(:overdue_show_more_button, :xpath => '//div[@data-cc-show-more-limit="overdueLimit"]/button')

    # TASKS: TODAY
    span(:today_task_count, :xpath => '//span[@data-ng-bind="dueTodayTasks.length"]')
    elements(:today_task, :list_item, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]')
    elements(:today_task_toggle, :div, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//span[contains(.,"Show")]/..')
    elements(:today_task_edit_button, :button, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//button[contains(.,"Edit")]')
    elements(:today_task_delete_button, :button, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//button[contains(.,"Delete")]')
    elements(:today_task_save_button, :button, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//button[contains(.,"Save")]')
    elements(:today_task_cancel_button, :button, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//button[contains(.,"Cancel")][2]')
    elements(:today_task_cbx, :checkbox, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//input[@id="cc-widget-tasks-checkbox-0"]')
    elements(:today_task_title, :div, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//strong[@data-ng-bind="task.title"]')
    elements(:today_task_course, :span, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//span[@data-ng-bind="task.course_code"]')
    elements(:today_task_title_input, :text_field, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//input[@data-ng-model="addEditTask.title"]')
    elements(:today_task_date, :div, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//div[@class="cc-widget-tasks-col cc-widget-tasks-col-date"]/span')
    elements(:today_task_time, :div, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//div[@data-ng-if="task.emitter==\'bCourses\' && task.dueDate.hasTime"]')
    elements(:today_task_date_input, :text_field, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//input[@name="add_task_due_date"]')
    elements(:today_task_notes_input, :text_field, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//textarea[@data-ng-model="addEditTask.notes"]')
    elements(:today_task_bcourses_link, :link, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//a[contains(.,"View in bCourses")]')
    button(:today_show_more_button, :xpath => '//div[@data-cc-show-more-limit="dueTodayLimit"]/button')
    paragraph(:today_task_date_validation_error, :xpath => '//li[@data-ng-repeat="task in dueTodayTasks | limitTo: dueTodayLimit"]//p[@data-ng-show="cc_widget_tasks_form.add_task_due_date.$error.ccDateValidator"]')

    # TASKS: FUTURE
    span(:future_task_count, :xpath => '//span[@data-ng-bind="futureTasks.length"]')
    elements(:future_task, :list_item, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]')
    elements(:future_task_toggle, :div, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//span[contains(.,"Show")]/..')
    elements(:future_task_edit_button, :button, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//button[contains(.,"Edit")]')
    elements(:future_task_delete_button, :button, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//button[contains(.,"Delete")]')
    elements(:future_task_save_button, :button, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//button[contains(.,"Save")]')
    elements(:future_task_cbx, :checkbox, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//input[@id="cc-widget-tasks-checkbox-0"]')
    elements(:future_task_title, :div, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//strong[@data-ng-bind="task.title"]')
    elements(:future_task_course, :span, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//span[@data-ng-bind="task.course_code"]')
    elements(:future_task_title_input, :text_field, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//input[@data-ng-model="addEditTask.title"]')
    elements(:future_task_date, :div, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//div[@class="cc-widget-tasks-col cc-widget-tasks-col-date"]/span')
    elements(:future_task_time, :div, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//div[@data-ng-if="task.emitter==\'bCourses\' && task.dueDate.hasTime"]')
    elements(:future_task_date_input, :text_field, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//input[@name="add_task_due_date"]')
    elements(:future_task_notes_input, :text_field, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//textarea[@data-ng-model="addEditTask.notes"]')
    elements(:future_task_bcourses_link, :link, :xpath => '//li[@data-ng-repeat="task in futureTasks | limitTo: futureLimit"]//a[contains(.,"View in bCourses")]')
    button(:future_show_more_button, :xpath => '//div[@data-cc-show-more-limit="futureLimit"]/button')

    # TASKS: UNSCHEDULED
    span(:unsched_task_count, :xpath => '//span[@data-ng-bind="unscheduledTasks.length"]')
    elements(:unsched_task, :list_item, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]')
    elements(:unsched_task_toggle, :div, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//span[contains(.,"Show")]/..')
    elements(:unsched_task_edit_button, :button, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//button[contains(.,"Edit")]')
    elements(:unsched_task_delete_button, :button, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//button[contains(.,"Delete")]')
    elements(:unsched_task_save_button, :button, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//button[contains(.,"Save")]')
    elements(:unsched_task_cbx, :checkbox, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//input[@id="cc-widget-tasks-checkbox-0"]')
    elements(:unsched_task_title, :div, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//strong[@data-ng-bind="task.title"]')
    elements(:unsched_task_title_input, :text_field, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//input[@data-ng-model="addEditTask.title"]')
    elements(:unsched_task_date, :div, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//div[@data-ng-if="task.updatedDate && task.bucket === \'Unscheduled\'"]/div')
    elements(:unsched_task_date_input, :text_field, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//input[@name="add_task_due_date"]')
    elements(:unsched_task_notes_input, :text_field, :xpath => '//li[@data-ng-repeat="task in unscheduledTasks | limitTo:unscheduledLimit"]//textarea[@data-ng-model="addEditTask.notes"]')
    button(:unsched_show_more_button, :xpath => '//div[@data-cc-show-more-limit="unscheduledLimit"]/button')

    # TASKS: COMPLETED
    span(:completed_task_count, :xpath => '//span[@data-ng-bind="completedTasks.length"]')
    elements(:completed_task, :list_item, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]')
    elements(:completed_task_toggle, :div, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//span[contains(.,"Show")]/..')
    elements(:completed_task_edit_button, :button, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//button[contains(.,"Edit")]')
    elements(:completed_task_delete_button, :button, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//button[contains(.,"Delete")]')
    elements(:completed_task_cbx, :checkbox, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//input[@id="cc-widget-tasks-checkbox-0"]')
    elements(:completed_task_title, :div, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//strong[@data-ng-bind="task.title"]')
    elements(:completed_task_title_input, :text_field, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//input[@data-ng-model="addEditTask.title"]')
    elements(:completed_task_date_input, :text_field, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//input[@name="add_task_due_date"]')
    elements(:completed_task_notes_input, :text_field, :xpath => '//li[@data-ng-repeat="task in completedTasks | limitTo:completedLimit"]//textarea[@data-ng-model="addEditTask.notes"]')
    button(:completed_show_more_button, :xpath => '//div[@data-cc-show-more-limit="completedLimit"]/button')

    def overdue_task_note_element(task_index)
      span_element(:xpath => "//li[@data-ng-repeat='task in overdueTasks | limitTo: overdueLimit'][#{task_index + 1}]//div[@data-cc-compile-directive='task.notes | linky']")
    end

    def today_task_note_element(task_index)
      span_element(:xpath => "//li[@data-ng-repeat='task in dueTodayTasks | limitTo: dueTodayLimit'][#{task_index + 1}]//div[@data-cc-compile-directive='task.notes | linky']")
    end

    def future_task_note_element(task_index)
      span_element(:xpath => "//li[@data-ng-repeat='task in futureTasks | limitTo: futureLimit'][#{task_index + 1}]//div[@data-cc-compile-directive='task.notes | linky']")
    end

    def unsched_task_note_element(task_index)
      span_element(:xpath => "//li[@data-ng-repeat='task in unscheduledTasks | limitTo:unscheduledLimit'][#{task_index + 1}]//div[@data-cc-compile-directive='task.notes | linky']")
    end

    # ADD NEW TASK

    def click_new_task
      WebDriverUtils.wait_for_page_and_click new_task_button_element
    end

    def click_cancel_task
      WebDriverUtils.wait_for_page_and_click cancel_new_task_button_element
      cancel_new_task_button_element.when_not_visible WebDriverUtils.page_event_timeout
    end

    def edit_new_task(title, date, note)
      logger.info "Task title is #{title}, date is #{date}, and note is #{note}"
      WebDriverUtils.wait_for_element_and_type(new_task_title_input_element, title) unless title.nil?
      if date.instance_of? String
        WebDriverUtils.wait_for_element_and_type(new_task_date_input_element, date)
      elsif date.instance_of? Date
        WebDriverUtils.wait_for_element_and_type(new_task_date_input_element, WebDriverUtils.ui_date_input_format(date))
      end
      WebDriverUtils.wait_for_element_and_type(new_task_notes_input_element, note) unless note.nil?
    end

    def click_add_task_button
      WebDriverUtils.wait_for_page_and_click add_new_task_button_element
      add_new_task_button_element.when_not_visible(timeout=WebDriverUtils.google_task_timeout)
    end

    def add_task(title, date, note)
      click_new_task
      edit_new_task(title, date, note)
      click_add_task_button
    end

    def wait_for_overdue_tasks
      WebDriverUtils.wait_for_element_and_click scheduled_tasks_tab_element
      wait_until(WebDriverUtils.google_task_timeout) { overdue_task_elements.any? }
    end

    def wait_for_today_tasks
      WebDriverUtils.wait_for_element_and_click scheduled_tasks_tab_element
      wait_until(WebDriverUtils.google_task_timeout) { today_task_elements.any? }
    end

    def wait_for_future_tasks
      WebDriverUtils.wait_for_element_and_click scheduled_tasks_tab_element
      wait_until(WebDriverUtils.google_task_timeout) { future_task_elements.any? }
    end

    def wait_for_unsched_tasks
      WebDriverUtils.wait_for_element_and_click unsched_tasks_tab_element
      wait_until(WebDriverUtils.google_task_timeout) { unsched_task_elements.any? }
    end

    def wait_for_completed_tasks
      WebDriverUtils.wait_for_element_and_click completed_tasks_tab_element
      wait_until(WebDriverUtils.google_task_timeout) { completed_task_elements.any? }
    end

    def show_overdue_task_detail(task_index)
      overdue_task_toggle_elements[task_index].click unless overdue_task_edit_button_elements[task_index].visible?
    end

    def show_today_task_detail(task_index)
      today_task_toggle_elements[task_index].click unless today_task_edit_button_elements[task_index].visible?
    end

    def show_future_task_detail(task_index)
      future_task_toggle_elements[task_index].click unless future_task_edit_button_elements[task_index].visible?
    end

    def show_unsched_task_detail(task_index)
      unsched_task_toggle_elements[task_index].click unless unsched_task_edit_button_elements[task_index].visible?
    end

    def edit_overdue_task(task_index, title, date, note)
      show_overdue_task_detail task_index
      WebDriverUtils.wait_for_element_and_click overdue_task_edit_button_elements[task_index]
      WebDriverUtils.wait_for_element_and_type(overdue_task_title_input_elements[task_index], title) unless title.nil?
      if date.instance_of? String
        WebDriverUtils.wait_for_element_and_type(overdue_task_date_input_elements[task_index], date)
      elsif date.instance_of? Date
        WebDriverUtils.wait_for_element_and_type(overdue_task_date_input_elements[task_index], WebDriverUtils.ui_date_input_format(date))
      end
      WebDriverUtils.wait_for_element_and_type(overdue_task_notes_input_elements[task_index], note) unless note.nil?
    end

    def edit_today_task(task_index, title, date, note)
      show_today_task_detail task_index
      WebDriverUtils.wait_for_element_and_click today_task_edit_button_elements[task_index]
      WebDriverUtils.wait_for_element_and_type(today_task_title_input_elements[task_index], title) unless title.nil?
      if date.instance_of? String
        WebDriverUtils.wait_for_element_and_type(today_task_date_input_elements[task_index], date)
      elsif date.instance_of? Date
        WebDriverUtils.wait_for_element_and_type(today_task_date_input_elements[task_index], WebDriverUtils.ui_date_input_format(date))
      end
      WebDriverUtils.wait_for_element_and_type(today_task_notes_input_elements[task_index], note) unless note.nil?
    end

    def edit_future_task(task_index, title, date, note)
      show_future_task_detail task_index
      WebDriverUtils.wait_for_element_and_click future_task_edit_button_elements[task_index]
      WebDriverUtils.wait_for_element_and_type(future_task_title_input_elements[task_index], title) unless title.nil?
      if date.instance_of? String
        WebDriverUtils.wait_for_element_and_type(future_task_date_input_elements[task_index], date)
      elsif date.instance_of? Date
        WebDriverUtils.wait_for_element_and_type(future_task_date_input_elements[task_index], WebDriverUtils.ui_date_input_format(date))
      end
      WebDriverUtils.wait_for_element_and_type(future_task_notes_input_elements[task_index], note) unless note.nil?
    end

    def edit_unsched_task(task_index, title, date, note)
      show_unsched_task_detail task_index
      WebDriverUtils.wait_for_element_and_click unsched_task_edit_button_elements[task_index]
      WebDriverUtils.wait_for_element_and_type(unsched_task_title_input_elements[task_index], title) unless title.nil?
      if date.instance_of? String
        WebDriverUtils.wait_for_element_and_type(unsched_task_date_input_elements[task_index], date)
      elsif date.instance_of? Date
        WebDriverUtils.wait_for_element_and_type(unsched_task_date_input_elements[task_index], WebDriverUtils.ui_date_input_format(date))
      end
      WebDriverUtils.wait_for_element_and_type(unsched_task_notes_input_elements[task_index], note) unless note.nil?
    end

    def edit_and_save_task(task_element, title, date, note)
      if overdue_task_elements.include? task_element
        wait_for_overdue_tasks
        task_index = overdue_task_elements.index(task_element)
        edit_overdue_task(task_index, title, date, note)
        WebDriverUtils.wait_for_element_and_click overdue_task_save_button_elements[task_index]
        overdue_task_save_button_elements[task_index].when_not_visible WebDriverUtils.google_task_timeout
      elsif today_task_elements.include? task_element
        wait_for_today_tasks
        task_index = today_task_elements.index(task_element)
        edit_today_task(task_index, title, date, note)
        WebDriverUtils.wait_for_element_and_click today_task_save_button_elements[task_index]
        today_task_save_button_elements[task_index].when_not_visible WebDriverUtils.google_task_timeout
      elsif future_task_elements.include? task_element
        wait_for_future_tasks
        task_index = future_task_elements.index(task_element)
        edit_future_task(task_index, title, date, note)
        WebDriverUtils.wait_for_element_and_click future_task_save_button_elements[task_index]
        future_task_save_button_elements[task_index].when_not_visible WebDriverUtils.google_task_timeout
      elsif unsched_task_elements.include? task_element
        wait_for_unsched_tasks
        task_index = unsched_task_elements.index(task_element)
        edit_unsched_task(task_index, title, date, note)
        WebDriverUtils.wait_for_element_and_click unsched_task_save_button_elements[task_index]
        unsched_task_save_button_elements[task_index].when_not_visible WebDriverUtils.google_task_timeout
      else
        logger.error 'Task not found in time bucket'
      end
    end

    def complete_task(task_element)
      if overdue_task_elements.include? task_element
        wait_for_overdue_tasks
        task_index = overdue_task_elements.index(task_element)
        task_count = overdue_task_count.to_i
        WebDriverUtils.wait_for_element_and_click overdue_task_cbx_elements[task_index]
        wait_until(WebDriverUtils.google_task_timeout) { overdue_task_count.to_i == (task_count - 1) }
      elsif today_task_elements.include? task_element
        wait_for_today_tasks
        task_index = today_task_elements.index(task_element)
        task_count = today_task_count.to_i
        WebDriverUtils.wait_for_element_and_click today_task_cbx_elements[task_index]
        wait_until(WebDriverUtils.google_task_timeout) { today_task_count.to_i == (task_count - 1) }
      elsif future_task_elements.include? task_element
        wait_for_future_tasks
        task_index = future_task_elements.index(task_element)
        task_count = future_task_count.to_i
        WebDriverUtils.wait_for_element_and_click future_task_cbx_elements[task_index]
        wait_until(WebDriverUtils.google_task_timeout) { future_task_count.to_i == (task_count - 1) }
      elsif unsched_task_elements.include? task_element
        wait_for_unsched_tasks
        task_index = unsched_task_elements.index(task_element)
        task_count = unsched_task_count.to_i
        WebDriverUtils.wait_for_element_and_click unsched_task_cbx_elements[task_index]
        wait_until(WebDriverUtils.google_task_timeout) { unsched_task_count.to_i == (task_count - 1) }
      else
        logger.error 'Task not found in time bucket'
      end
    end

    def delete_all_tasks
      logger.info('Deleting all existing tasks')
      tries = 2
      begin
        load_page
        WebDriverUtils.wait_for_page_and_click scheduled_tasks_tab_element
        while overdue_task_toggle_elements.any? do
          task_count = overdue_task_count.to_i
          WebDriverUtils.wait_for_element_and_click overdue_task_toggle_elements[0]
          WebDriverUtils.wait_for_element_and_click overdue_task_delete_button_elements[0]
          wait_until(WebDriverUtils.google_task_timeout) { overdue_task_count.to_i == (task_count - 1) }
        end
        while today_task_toggle_elements.any? do
          task_count = today_task_count.to_i
          WebDriverUtils.wait_for_element_and_click today_task_toggle_elements[0]
          WebDriverUtils.wait_for_element_and_click today_task_delete_button_elements[0]
          wait_until(WebDriverUtils.google_task_timeout) { today_task_count.to_i == (task_count - 1) }
        end
        while future_task_toggle_elements.any? do
          task_count = future_task_count.to_i
          WebDriverUtils.wait_for_element_and_click future_task_toggle_elements[0]
          WebDriverUtils.wait_for_element_and_click future_task_delete_button_elements[0]
          wait_until(WebDriverUtils.google_task_timeout) { future_task_count.to_i == (task_count - 1) }
        end
        WebDriverUtils.wait_for_page_and_click unsched_tasks_tab_element
        while unsched_task_toggle_elements.any? do
          task_count = unsched_task_count.to_i
          WebDriverUtils.wait_for_element_and_click unsched_task_toggle_elements[0]
          WebDriverUtils.wait_for_element_and_click unsched_task_delete_button_elements[0]
          wait_until(WebDriverUtils.google_task_timeout) { unsched_task_count.to_i == (task_count - 1) }
        end
        WebDriverUtils.wait_for_element_and_click completed_tasks_tab_element
        while completed_task_toggle_elements.any? do
          task_count = completed_task_count.to_i
          WebDriverUtils.wait_for_element_and_click completed_task_toggle_elements[0]
          WebDriverUtils.wait_for_element_and_click completed_task_delete_button_elements[0]
          wait_until(WebDriverUtils.google_task_timeout) { completed_task_count.to_i == (task_count - 1) }
        end
      rescue
        # Retry since Google responses can sometimes hang when too many deletions occur too rapidly, causing test timeout
        retry unless (tries -= 1).zero?
      end
    end

    def verify_task(task_element, title, date, note)
      if overdue_task_elements.include? task_element
        wait_for_overdue_tasks
        task_index = overdue_task_elements.index(task_element)
        wait_until(WebDriverUtils.google_task_timeout) do
          show_overdue_task_detail task_index
          overdue_task_title_elements[task_index].text == title
          overdue_task_date_elements[task_index].text == WebDriverUtils.ui_numeric_date_format(date)
          note.blank? ? !overdue_task_note_element(task_index).exists? : overdue_task_note_element(task_index).text == note
        end
      elsif today_task_elements.include? task_element
        wait_for_today_tasks
        task_index = today_task_elements.index(task_element)
        wait_until(WebDriverUtils.google_task_timeout) do
          show_today_task_detail task_index
          today_task_title_elements[task_index].text == title
          today_task_date_elements[task_index].text == WebDriverUtils.ui_numeric_date_format(date)
          note.blank? ? !today_task_note_element(task_index).exists? : today_task_note_element(task_index).text == note
        end
      elsif future_task_elements.include? task_element
        wait_for_future_tasks
        task_index = future_task_elements.index(task_element)
        wait_until(WebDriverUtils.google_task_timeout) do
          show_future_task_detail task_index
          future_task_title_elements[task_index].text == title
          future_task_date_elements[task_index].text == WebDriverUtils.ui_numeric_date_format(date)
          note.blank? ? !future_task_note_element(task_index).exists? : future_task_note_element(task_index).text == note
        end
      elsif unsched_task_elements.include? task_element
        wait_for_unsched_tasks
        task_index = unsched_task_elements.index(task_element)
        wait_until(WebDriverUtils.google_task_timeout) do
          show_unsched_task_detail task_index
          unsched_task_title_elements[task_index].text == title
          note.blank? ? !unsched_task_note_element(task_index).exists? : unsched_task_note_element(task_index).text == note
        end
      else
        logger.error 'Task not found in time bucket'
      end
    end

  end
end
