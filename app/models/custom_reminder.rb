class CustomReminder < ActiveRecord::Base
  has_and_belongs_to_many :projects,
                          class_name: 'Project',
                          foreign_key: 'custom_reminder_id',
                          association_foreign_key: 'project_id'
  projects_join_table = reflect_on_association(:projects).join_table
  scope :active, -> { where(active: true) }
  scope :for_project, (lambda do |project|
    where("EXISTS (SELECT * FROM #{projects_join_table} WHERE project_id=? AND custom_reminder_id=id)", project.id)
  end)

  validates :interval, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 31 }

  def self.trigger_types
    @trigger_type ||= (2..31).map { |i| [l(:label_trigger_updated_on, count: i), i] } +
                      [["**#{l(:label_custom_reminders_user_type)}**", -1]]
  end

  def self.notification_recipient_names
    @recipients ||= CustomField.where(field_format: 'user').map { |r| [r.name, r.id] } +
                    [["**#{l(:label_custom_reminders_user_type)}**", -1], ["*#{l(:field_assigned_to)}*", -2],
                     ["*#{l(:label_custom_reminder_to_author_and_watchers)}*", -3]]
  end

  def self.trigger_type_name(id = nil)
    return nil if id.nil?
    trigger_types.detect { |trigger| trigger.last == id }&.first
  end

  def self.notification_recipient_name(id = nil)
    return nil if id.nil?
    notification_recipient_names.detect { |recipient| recipient.last == id }&.first
  end

  def prepare_and_run_custom_reminder(options = {})
    projects = options[:projects]
    trigger = options[:trigger]
    trigger_param = options[:trigger_param]
    target = options[:target]

    user_scope_script = read_attribute('user_scope_script')
    trigger_script = read_attribute('trigger_script')

    issues_hash = {} # Key=user, value=issue
    issues_list = []
    case trigger
    when :updated_on
      Issue.open.where(project: projects).each do |issue|
        issues_list << issue if issue.updated_on <= trigger_param.day.until(Date.today)
      end
    when :custom_trigger
      instance_eval(trigger_script)
    end

    case target
    when :assigned_to
      issues_list.each do |issue|
        issues_hash[issue.assigned_to] ||= []
        issues_hash[issue.assigned_to] << issue
      end
    when :all_awa
      issues_list.each do |issue|
        issues_hash[issue.assigned_to] ||= []
        issues_hash[issue.assigned_to] << issue
        issues_hash[issue.author] ||= []
        issues_hash[issue.author] << issue
        issue.watchers.each do |w|
          issues_hash[w.user] ||= []
          issues_hash[w.user] << issue
        end
      end
    when :role
      role_id = notification_recipient
      issues_list.each do |issue|
        user_id = issue.custom_field_value(role_id)
        next if user_id.nil? || user_id.empty?
        user = User.find_by_id(user_id)
        issues_hash[user] ||= []
        issues_hash[user] << issue
      end
    when :user_scope
      instance_eval(user_scope_script)
    end
    CustomRemindersMailer.custom_reminders(issues_hash, projects, self)
  rescue StandardError => e
    Rails.logger.error "== Custom reminder exception: #{e.message}\n #{e.backtrace.join("\n ")}"
  end
end
