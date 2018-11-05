set :output, error: '/home/red2mine/red2mine/log/cron.stderr.log', standard: '/home/red2mine/red2mine/log/cron.stdout.log'
ENV.each { |k, v| env(k, v) }

every 1.minutes do
  runner 'ScheduleEmailNotificationJob.perform_now'
end
