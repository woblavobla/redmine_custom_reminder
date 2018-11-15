class CustomRemindersEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    custom_reminders = CustomReminder.all.to_a
    options = { force: args&.first[:force] }
    custom_reminders.each do |cr|
      execute_reminder(cr, options)
    end
    Rails.logger.debug("CustomRemindersEmailNotificationJob performed for #{custom_reminders.size} custom_reminders")
  end

  def execute_reminder(custom_reminder, options = {})
    unless options[:force]
      if Date.today < custom_reminder.executed_at.to_date + custom_reminder.interval
        Rails.logger.debug("#{custom_reminder} wasn't executed cause of interval and will be executed at #{custom_reminder.executed_at.to_date + custom_reminder.interval};")
        return
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
  end
end
