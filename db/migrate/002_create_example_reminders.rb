class CreateExampleReminders < ActiveRecord::Migration[5.2]
  def change
    days1 = %w[0 1 2 3 4 5 6]
    CustomReminder.create!(name: 'Alarm for issue due date',
                           active: false, send_days: days1.to_yaml, notification_recipient: -2, description: <<~DESCRIPTION, trigger_script: <<~TRIGGER)
                             Notify users about tasks that will have expire in 1 day.
                           DESCRIPTION
                             cur_date = Date.today
                             Issue.open.where(project: projects).each do |issue|
                               issues_list << issue if issue.due_date == cur_date + 1
                             end
                           TRIGGER
    days2 = %w[1 2 3 4 5]
    CustomReminder.create!(name: 'Notification of tasks in stagnation',
                           active: false, send_days: days2.to_yaml, notification_recipient: -1,
                           description: <<~DESCRIPTION, trigger_script: <<~TRIGGER, user_scope_script: <<~USER_SCRIPT)
                             Notify users about issues that haven't changed in 7 days.
                           DESCRIPTION
                             cur_date = Date.today
                             Issue.open.where(project: projects).each do |issue|
                               issues_list << issue if issue.updated_on < 7.day.until(cur_date)
                             end
                           TRIGGER
                             # Example with sending like in editing issue to assignee, watchers and author
                             issues_list.each do |issue|
                               issues_hash[issue.assigned_to] ||= []
                               issues_hash[issue.assigned_to] << issue
                               issues_hash[issue.author] ||= []
                               issues_hash[issue.author] << issue
                               issue.watchers.each do |w|
                                 issues_hash[w.user] ||= []
                                 issues_hash[w.user] << issue
                               end
                             end
                           USER_SCRIPT
  end
end
