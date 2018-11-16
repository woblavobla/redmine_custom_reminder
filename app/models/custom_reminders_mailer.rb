class CustomRemindersMailer < Mailer
  layout 'mailer'

  def custom_reminder(user, issues, params = {})
    @issues = issues
    @custom_reminder = params[:custom_reminder]
    @projects = params[:projects] unless params[:projects].nil?
    @projects = @projects.select { |p| @issues.any? { |i| i.project == p } } if @projects
    query = IssueQuery.new
    query.add_filter 'issue_id', '=', [@issues.map(&:id).join(',')]
    query.filters = query.filters.except('status_id')
    query.column_names = %w[project tracker status priority subject assigned_to updated_on]
    query.sort_criteria = [%w[updated_on desc]]
    query.group_by = 'project'
    query.filters
    q_params = query.as_params

    @issues_url = Rails.application.routes.url_helpers.issues_path(q_params)
    @issues_url = "http://#{Setting['host_name']}#{@issues_url}"

    mail to: user,
         subject: l(:mail_custom_reminder_subject, count: issues.size)
  end

  def self.custom_reminders(issues_by_user = {}, projects = [], custom_reminder = nil)
    issues_by_user.each do |assignee, issues|
      if assignee.is_a?(User) && assignee.active? && issues.present?
        visible_issues = issues.select { |i| i.visible?(assignee) }
        custom_reminder(assignee, visible_issues, projects: projects, custom_reminder: custom_reminder).deliver_later if visible_issues.present?
      end
    end
  end
end
