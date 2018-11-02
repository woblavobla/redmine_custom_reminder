require File.expand_path('plugins/redmine_custom_reminder/app/jobs/schedule_email_notification_job', Rails.root)
every 1.minutes do
  runner 'ScheduleEmailNotificationJob.perform_now'
end
