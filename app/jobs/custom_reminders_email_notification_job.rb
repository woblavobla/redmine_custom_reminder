class CustomRemindersEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    custom_reminders = CustomReminder.all.to_a
    custom_reminders.each do |cr|
      execute_reminder(cr, args)
    end
    puts "CustomRemindersEmailNotificationJob performed #{args}"
    Rails.logger.debug("CustomRemindersEmailNotificationJob performed #{args}")
  end

  def execute_reminder(custom_reminder, *_args)
    case custom_reminder.trigger_type
    when 1
      if custom_reminder.notification_recipient == -2
        projects = custom_reminder.projects.to_a
        users = projects.map { |pr| pr.issues.open.map(&:assigned_to) }.flatten.compact.uniq.map(&:id)
        CustomRemindersMailer.custom_reminders(projects: projects, users: users, trigger: 'due_date',
                                               trigger_param: 5, notification_recipient: 'assigned_to')
      end
    end
  end
end
