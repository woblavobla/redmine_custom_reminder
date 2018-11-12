class CustomRemindersMailer < Mailer
  layout 'mailer'

  def custom_reminder(user, issues, params = {})
    @issues = issues
    @issues_url = url_for(controller: 'issues', action: 'index',
                          set_filter: 1, assigned_to_id: user.id,
                          sort: 'due_date:asc')
    @projects = params[:projects] unless params[:projects].nil?
    @projects = @projects.select { |p| @issues.any? { |i| i.project == p } } if @projects

    mail to: user,
         subject: l(:mail_custom_reminder_subject, count: issues.size)
  end

  def self.custom_reminders(options = {})
    user_ids = options[:users]
    projects = options[:projects] ? Project.where(id: options[:projects]).to_a : nil
    watchers = options[:watchers]
    authors = options[:authors]

    scope = Issue.open
    scope = scope.where("#{Project.table_name}.status = #{Project::STATUS_ACTIVE}") if projects
    scope = scope.where("#{Issue.table_name}.updated_on <= ?", options[:trigger_param].day.until(Date.today)) if options[:trigger] == 'updated_on'
    scope = scope.where(assigned_to_id: user_ids) if user_ids.present? && options[:notification_recipient] == 'assigned_to'

    scope = scope.where(custom_values: { custom_field_id: options[:role_id].to_i, value: user_ids }) if options[:role_id].present?

    if options[:notification_recipient] == 'all_awa'
      scope = scope.where("(#{Issue.table_name}.assigned_to_id in (?) OR #{Issue.table_name}.author_id in (?) OR #{Watcher.table_name}.user_id in (?))",
                          user_ids, authors, watchers)
    end

    scope = scope.where(project_id: projects) if projects

    issues_by_user = nil
    if options[:notification_recipient] == 'assigned_to'
      issues_by_user = scope.includes(:status, :assigned_to, :project, :tracker, :custom_values)
                            .group_by(&:assigned_to)
    elsif options[:role_id].present?
      issues_by_user = scope.includes(:status, :assigned_to, :project, :tracker, :custom_values)
                            .group_by { |i| User.find_by_id(i.custom_field_value(options[:role_id].to_i)) }
    elsif options[:notification_recipient] == 'all_awa'
      issues_by_user = scope.includes(:status, :assigned_to, :project, :tracker, :author, :watchers)
                            .group_by(&:assigned_to)
      first_scope = scope.includes(:status, :assigned_to, :project, :tracker, :author, :watchers)
                         .group_by(&:author)
      second_scope = scope.includes(:status, :assigned_to, :project, :tracker, :author, :watchers)
                          .group_by { |i| i.watchers.map(&:user) }
      first_scope.keys.each do |author|
        next unless author.is_a?(Group)
        author.users.each do |user|
          issues_by_user[user] ||= []
          issues_by_user[user] += first_scope[author]
        end
      end
      second_scope.keys.each do |watcher|
        if watcher.is_a?(Array)
          watcher.each do |user|
            issues_by_user[user] ||= []
            issues_by_user[user] += second_scope[watcher]
          end
        end
        next unless watcher.is_a?(Group)
        watcher.users.each do |user|
          issues_by_user[user] ||= []
          issues_by_user[user] += second_scope[watcher]
        end
      end
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
