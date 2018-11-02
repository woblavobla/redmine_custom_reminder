set :job_template, :nil
set :output, error: '/home/red2mine/red2mine/log/cron.stderr.log', standard: '/home/red2mine/red2mine/log/cron.stdout.log'
env :PATH, ENV['PATH']
set :bundle_command, 'bundle exec'
job_type :runner,  "cd :path && :bundle_command rails runner -e :environment ':task' :output"

every 1.minutes do
  runner 'ScheduleEmailNotificationJob.perform_now'
end
