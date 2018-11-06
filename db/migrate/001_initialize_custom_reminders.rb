class InitializeCustomReminders < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_reminders do |t|
      t.column :name, :string, limit: 200, null: false
      t.column :description, :text
      t.column :interval, :integer, default: 0, max: 31, min: 0, null: false
      t.column :executed_at, :datetime
      t.column :condition_type, :integer, default: 0, null: false
      t.column :remind_type, :integer, default: 0, null: false
      t.column :user_list_script, :text, default: nil
      t.column :condition_script, :text, default: nil
      t.column :active, :boolean, default: false, null: false
      t.timestamps
    end

    create_table :custom_reminders_projects do |t|
      t.belongs_to :custom_reminder
      t.belongs_to :project
    end
  end
end
