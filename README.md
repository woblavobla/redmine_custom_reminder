Plugins that allows to create custom email reminders;
Inspired by Redmine Custom Workflows;

**Minimum Rails version - 5.2**

Regular plugin installation:
1) Clone repository to your plugins dir
2) Create application_job.rb in app/jobs/application_job.rb with following content

    ```ruby
    class ApplicationJob < ActiveJob::Base
      # Automatically retry jobs that encountered a deadlock
      # retry_on ActiveRecord::Deadlocked
    
      # Most jobs are safe to ignore if the underlying records are no longer available
      # discard_on ActiveJob::DeserializationError
    end
    ```

3) bundle install # Installing whenever gem
4) rake redmine:plugins # Migrating db
5) bundle exec whenever -i redmine_custom_reminder -f plugins/redmine_custom_reminder/config/schedule.rb # Call from redmine root path
After last action scheduler will start at 10:00 am every day. You can change it in *plugins/redmine_custom_reminder/config/schedule.rb*.