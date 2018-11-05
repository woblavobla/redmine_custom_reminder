class ScheduleEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    project = Project.find_by_identifier('red2mine')
    issues_list = []
    current_date = DateTime.now
    project.issues.open.find_each(batch_size: 50) do |issue|
      issues_list << issue if current_date.diff(issue.updated_on)[:days] <= 5
    end
    puts "ScheduleEmailNotificationJob performed #{args}"
    Rails.logger.debug("ScheduleEmailNotificationJob performed #{args}")
  end
end
