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

  TRIGGER_TYPE = (2..31).map { |i| [l(:label_trigger_updated_on, count: i), i] } +
                 [["**#{l(:label_custom_reminders_user_type)}**", -1]]
  NOTIFICATION_RECIPIENTS = CustomField.where(field_format: 'user').map { |r| [r.name, r.id] } +
                            [["**#{l(:label_custom_reminders_user_type)}**", -1], ["**#{l(:field_assigned_to)}**", -2],
                             ["**#{l(:label_custom_reminder_to_author_and_watchers)}**", -3]]

  def self.trigger_type_name(id = nil)
    return nil if id.nil?
    TRIGGER_TYPE.detect { |trigger| trigger.last == id }&.first
  end

  def self.notification_recipient_name(id = nil)
    return nil if id.nil?
    NOTIFICATION_RECIPIENTS.detect { |recipient| recipient.last == id }&.first
  end

  def prepare_and_run_custom_reminder(options = {})
    projects = options[:projects]
    user_scope_script = read_attribute('user_scope_script')
    trigger_script = read_attribute('trigger_script')
    if user_scope_script.nil? || user_scope_script.empty? ||
       trigger_script.nil? || trigger_script.empty?
      Rails.logger.error('User script or trigger is nil or empty!') if logger
      return
    end
    issues_hash = {} # Key=user, value=issue
    issues_list = []
    Issue.open.where(project: projects).each(batch_size: 50) do |issue|
      instance_eval(trigger_script)
    end
    issues_list.each do |issue|
      instance_eval(user_scope_script)
    end
    issues_hash.each do |user, issues|
      if user.is_a?(User) && user.active? && issues.present?
        visible_issues = issues.select { |i| i.visible?(user) }
        custom_reminder(user, visible_issues, projects: projects).deliver_later if visible_issues.present?
      end
    end
  rescue StandardError => e
    Rails.logger.error "== Custom reminder exception: #{e.message}\n #{e.backtrace.join("\n ")}"
  end
end
