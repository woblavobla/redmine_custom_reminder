require 'redmine'

Redmine::Plugin.register :redmine_custom_reminder do
  name 'Redmine custom email reminder'
  author 'Andrey Lobanov(RedSoft)'
  description 'Sends email notifications by custom conditions'
  version '0.1.0'

  permission :edit_issue_reminder, custom_reminders: :index

  project_module :custom_reminder do
    permission :edit_issue_reminder, mail_reminders: :index
  end

  menu :project_menu,
       :custom_reminder,
       { controller: 'custom_reminders', action: :index },
       last: true,
       param: :project_id,
       if: proc { |project| project.enabled_module_names.include?('custom_reminder') }
end
