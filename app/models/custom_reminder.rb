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

  CONDITION_TYPE = [['Не обновлялась 5 дней', 1]] + [["**#{l(:label_custom_reminders_user_type)}**", -1]]
  REMIND_TYPE = Role.all.map { |r| [r.name, r.id] } + [["**#{l(:label_custom_reminders_user_type)}**", -1]]
end
