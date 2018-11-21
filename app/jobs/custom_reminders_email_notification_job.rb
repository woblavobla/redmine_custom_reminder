class CustomRemindersEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    custom_reminders = CustomReminder.active.to_a
    options = {}
    args.each do |arg|
      options[:force] = arg.try(:[], :force)
    end
    custom_reminders.each do |cr|
      execute_reminder(cr, options)
    end
    if logger
      logger.debug("CustomRemindersEmailNotificationJob performed for #{custom_reminders.size} custom_reminders")
    else
      puts "CustomRemindersEmailNotificationJob performed for #{custom_reminders.size} custom_reminders"
    end
  end

  def execute_reminder(custom_reminder, options = {})
    toggle_active = nil
    unless options[:force]
      today_date = Date.today
      current_wday = today_date.wday
      if today_date == custom_reminder.executed_at
        Rails.logger.debug("##{custom_reminder.id} CR already executed today")
        return
      end
      case custom_reminder.interval.to_i
      when -3
        date_to_execute = custom_reminder.date_to_execute
        if date_to_execute.nil? || today_date < date_to_execute
          Rails.logger.debug("##{custom_reminder.id} CR not executed because date to execute is #{date_to_execute}")
          return
        else
          toggle_active = true
        end
      when -2
        if [0, 6].include?(current_wday)
          Rails.logger.debug("##{custom_reminder.id} CR will not be executed cause of weekend")
          return
        end
      when 0..6
        if custom_reminder.interval.to_i != current_wday # return if not today
          Rails.logger.debug("##{custom_reminder.id} CR won't execute cause today is not a #{custom_reminder.interval.to_i} (wday - 0 is sunday)")
          return
        end
      end
    end
    projects = custom_reminder.projects.to_a
    trigger_type = custom_reminder.trigger_type.to_i
    target = case custom_reminder.notification_recipient.to_i
             when -3 # Author, assignee, watchers
               :all_awa
             when -2 # Assigned to
               :assigned_to
             when -1 # User defined
               :user_scope
             else
               :role
             end
    case trigger_type
    when 2..31 # Updated more than or equal to 2..31 days ago
      custom_reminder.prepare_and_run_custom_reminder(projects: projects, trigger: :updated_on,
                                                      trigger_param: trigger_type, target: target)
    when -1 # Section for user defined script
      custom_reminder.prepare_and_run_custom_reminder(projects: projects, trigger: :custom_trigger,
                                                      trigger_param: trigger_type, target: target)
    end
    custom_reminder.update_attribute(:executed_at, Time.now)
    custom_reminder.update_attribute(:active, false) if toggle_active
  end
end
