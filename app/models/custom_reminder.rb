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

  class << self
    def notification_recipient_names
      @recipients ||= CustomField.where(field_format: 'user').map { |r| [r.name, r.id] } +
          [["*#{l(:field_assigned_to)}*", -2],
           ["*#{l(:label_custom_reminder_to_author_and_watchers)}*", -3],
           ["**#{l(:label_custom_reminders_user_type)}**", -1]]
    end

    def send_days_array
      @send_days ||= (0..6).map do |i|
        [I18n.t('date.day_names')[i].to_s, i]
      end
    end

    def notification_recipient_name(id = nil)
      return nil if id.nil?
      notification_recipient_names.detect { |recipient| recipient.last == id }&.first
    end

    def import_from_yml(yml = nil)
      raise StandardError 'Yml is nil' if yml.nil?
      hash = YAML.load(yml)
      hash[:send_days] = YAML.load(hash[:send_days]) if hash[:send_days].present?
      CustomReminder.new(hash)
    end
  end

  def send_days
    value = super
    value.nil? ? nil : YAML.safe_load(value)
  end

  def prepare_and_run_custom_reminder(options = {})
    projects = options[:projects]
    target = options[:target]

    user_scope_script = read_attribute('user_scope_script')
    trigger_script = read_attribute('trigger_script')

    issues_hash = {} # Key=user, value=issue
    issues_list = []
    instance_eval(trigger_script) # Execute trigger script

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

  def export_as_yaml
    fields = %i[name description send_days notification_recipient user_scope_script trigger_script active]
    object_hash = {}
    fields.each { |f| object_hash[f] = self[f] }
    object_hash.to_yaml
  end

end
