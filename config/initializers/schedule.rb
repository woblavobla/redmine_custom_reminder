every 1.minutes do
  require File.expand_path('plugins/redmine_custom_reminder/app/jobs/schedule_email_notification_job', Rails.root)
  runner 'ScheduleEmailNotificationJob.perform_now'
end
