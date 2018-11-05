set :output, error: '/home/red2mine/red2mine/log/cron.stderr.log', standard: '/home/red2mine/red2mine/log/cron.stdout.log'
%w[PATH BUNDLE_PATH GEM_HOME RAILS_ENV PWD GEM_PATH].each do |envir|
  env(envir, ENV[envir])
end

every 1.minutes do
  runner 'CustomRemindersEmailNotificationJob.perform_now'
end
