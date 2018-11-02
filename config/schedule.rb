set :job_template, :nil
set :output, error: '/home/red2mine/red2mine/log/cron.stderr.log', standard: '/home/red2mine/red2mine/log/cron.stdout.log'
env :PATH, ENV['PATH']

every 1.minutes do
  runner 'ScheduleEmailNotificationJob.perform_now'
end
