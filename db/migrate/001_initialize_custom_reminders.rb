class InitializeCustomReminders < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_reminders do |t|
      t.column :name, :string, limit: 200, null: false
      t.column :description, :text
      t.column :send_days, :string, null: true
      t.column :executed_at, :datetime
      t.column :trigger_type, :integer, default: 0, null: false
      t.column :notification_recipient, :integer, default: 0, null: false
      t.column :user_scope_script, :text, default: nil
      t.column :trigger_script, :text, default: nil
      t.column :active, :boolean, default: false, null: false
      t.timestamps
    end

    create_table :custom_reminders_projects do |t|
      t.belongs_to :custom_reminder
      t.belongs_to :project
    end
  end
end
