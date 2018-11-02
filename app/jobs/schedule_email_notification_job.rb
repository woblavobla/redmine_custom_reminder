class ScheduleEmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "ScheduleEmailNotificationJob performed #{args}"
  end
end
