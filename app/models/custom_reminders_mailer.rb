class CustomRemindersMailer < Mailer
  layout 'mailer'

  def custom_reminder(user, issues, params = {})
    @issues = issues
    @issues_url = url_for(controller: 'issues', action: 'index',
                          set_filter: 1, assigned_to_id: user.id,
                          sort: 'due_date:asc')
    @projects = params[:projects] unless params[:projects].nil?

    mail to: user,
         subject: l(:mail_custom_reminder_subject, count: issues.size)
  end

  def self.custom_reminders(options = {})
    user_ids = options[:users]
    projects = options[:projects] ? Project.where(id: options[:projects]).to_a : nil

    scope = Issue.open.where("#{Project.table_name}.status = #{Project::STATUS_ACTIVE}")
    scope = scope.where("#{Issue.table_name}.updated_on <= ?", options[:trigger_param].day.until(Date.today)) if options[:trigger] == 'updated_on'
    scope = scope.where(assigned_to_id: user_ids) if user_ids.present? && options[:notification_recipient] == 'assigned_to'

    scope = scope.where(custom_values: { custom_field_id: options[:role_id].to_i, value: user_ids }) if options[:role_id].present?

    scope = scope.where(project_id: projects) if projects

    issues_by_user = nil
    if options[:notification_recipient] == 'assigned_to'
      issues_by_user = scope.includes(:status, :assigned_to, :project, :tracker, :custom_values)
                            .group_by(&:assigned_to)
    elsif options[:role_id].present?
      issues_by_user = scope.includes(:status, :assigned_to, :project, :tracker, :custom_values)
                            .group_by { |i| User.find_by_id(i.custom_field_value(options[:role_id].to_i)) }
    end

    issues_by_user.keys.each do |assignee|
      next unless assignee.is_a?(Group)
      assignee.users.each do |user|
        issues_by_user[user] ||= []
        issues_by_user[user] += issues_by_user[assignee]
      end
    end

    issues_by_user.each do |assignee, issues|
      if assignee.is_a?(User) && assignee.active? && issues.present?
        visible_issues = issues.select { |i| i.visible?(assignee) }
        custom_reminder(assignee, visible_issues, projects: projects).deliver_later if visible_issues.present?
      end
    end
  end
end
