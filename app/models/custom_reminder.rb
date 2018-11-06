class CustomReminder < ActiveRecord::Base
  has_and_belongs_to_many :projects,
                          class_name: 'Project',
                          foreign_key: 'custom_reminders_id',
                          association_foreign_key: 'project_id'
  projects_join_table = reflect_on_association(:projects).join_table
  scope :active, lambda { where(:active => true) }
  scope :for_project, (lambda do |project|
    where("EXISTS (SELECT * FROM #{projects_join_table} WHERE project_id=? AND custom_reminders_id=id)", project.id)
  end)

end