# Custom Reminders notification job
class CustomRemindersJob < ApplicationJob
  queue_as :custom_reminders

  def perform(*args)
    custom_reminders = CustomReminder.active.to_a
    options = {}
    args.each do |arg|
      options[:force] = arg.try(:[], :force)
    end
    custom_reminders.each do |cr|
      execute_reminder(cr, options)
    end
    logger&.debug("CustomRemindersJob performed for #{custom_reminders.size} custom_reminders")
  end

  def execute_reminder(custom_reminder, options = {})
    unless options[:force]
      today_date = Date.today
      current_wday = today_date.wday
      if today_date == custom_reminder.executed_at
        Rails.logger.debug("##{custom_reminder.id} CR already executed today")
        return
      end
      unless custom_reminder.send_days&.include?(current_wday.to_s)
        Rails.logger.debug("##{custom_reminder.id} CR won't start cause wday #{current_wday} is not selected")
        return
      end
    end
    projects = custom_reminder.projects.to_a
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
    custom_reminder.prepare_and_run_custom_reminder(projects: projects, target: target)
    custom_reminder.update_attribute(:executed_at, Time.now)
  end
end
