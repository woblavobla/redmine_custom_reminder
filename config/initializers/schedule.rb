every 1.minutes do
  runner 'ScheduleEmailNotificationJob.perform_now'
end
