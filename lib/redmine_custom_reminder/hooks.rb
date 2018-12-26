module RedmineCustomReminder
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context)
      stylesheet_link_tag :custom_reminders, plugin: 'redmine_custom_reminder'
    end
  end
end
