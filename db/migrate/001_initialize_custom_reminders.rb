class InitializeCustomReminders < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_reminders do |t|
      t.column :name, :string, limit: 200, null: false
      t.column :description, :text
      t.column :interval, :string, limit: 30, default: '1'
      t.column :executed_at, :datetime
      t.column :user_list_script, :text
      t.column :condition_script, :text
      t.column :active, :boolean
      t.timestamps
    end

    create_table :custom_reminders_projects do |t|
      t.belongs_to :custom_reminders
      t.belongs_to :project
    end
  end
end
