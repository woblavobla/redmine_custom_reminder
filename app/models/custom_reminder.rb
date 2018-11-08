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
end
