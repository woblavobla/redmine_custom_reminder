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
    case custom_reminder.trigger_type
    when 2..31 # Updated more than or equal to 2..31 days ago
      projects = custom_reminder.projects.to_a
      case custom_reminder.notification_recipient
      when -3 # Author, assignee, watchers
        assigned_to = projects.map { |pr| pr.issues.open.map(&:assigned_to) }.flatten.compact.uniq.map(&:id)
        watchers = projects.map { |pr| pr.issues.open.map { |i| i.watchers.map(&:user) } }.flatten.compact.uniq.map(&:id)
        authors = projects.map { |pr| pr.issues.open.map(&:author) }.flatten.compact.uniq.map(&:id)
        CustomRemindersMailer.custom_reminders(projects: projects, users: assigned_to, trigger: 'updated_on',
                                               watchers: watchers, author: authors,
                                               trigger_param: custom_reminder.trigger_type.to_i, notification_recipient: 'all_awa')
      when -2 # Assigned to
        users = projects.map { |pr| pr.issues.open.map(&:assigned_to) }.flatten.compact.uniq.map(&:id)
        CustomRemindersMailer.custom_reminders(projects: projects, users: users, trigger: 'updated_on',
                                               trigger_param: custom_reminder.trigger_type.to_i, notification_recipient: 'assigned_to')
      when -1 # User defined
        # TODO
      else
        role_id = custom_reminder.notification_recipient
        unless role_id.nil?
          users = projects.map { |pr| pr.issues.open.includes(:custom_values).map { |i| i.custom_field_value(role_id) } }
                          .flatten.compact.uniq.map(&:to_i).reject(&:zero?)
          CustomRemindersMailer.custom_reminders(projects: projects, users: users, trigger: 'updated_on',
                                                 trigger_param: custom_reminder.trigger_type.to_i, notification_recipient: 'role',
                                                 role_id: role_id)
        end
      end
    when -1 # Section for user defined script
      # TODO
    end
    custom_reminder.update_attribute(:executed_at, Time.now)
  end
end
