class CustomRemindersMailer < Mailer
  layout 'mailer'

  def custom_reminder(user, issues, params = {})
    @issues = issues
    @issues_url = url_for(controller: 'issues', action: 'index',
                          set_filter: 1, assigned_to_id: user.id,
                          sort: 'due_date:asc', issue_id: @issues.map(&:id))
    @projects = params[:projects] unless params[:projects].nil?
    @projects = @projects.select { |p| @issues.any? { |i| i.project == p } } if @projects

    mail to: user,
         subject: l(:mail_custom_reminder_subject, count: issues.size)
  end

  def self.custom_reminders(issues_by_user = {}, projects = [])
    issues_by_user.each do |assignee, issues|
      if assignee.is_a?(User) && assignee.active? && issues.present?
        visible_issues = issues.select { |i| i.visible?(assignee) }
        custom_reminder(assignee, visible_issues, projects: projects).deliver_later if visible_issues.present?
      end
    end
  end
end
