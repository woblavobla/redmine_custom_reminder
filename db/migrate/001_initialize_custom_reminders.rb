class InitializeCustomReminders < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_reminders do |t|
      t.belongs_to :project
      t.column :interval, :string, limit: 30
      t.column :executed_at, :datetime
      t.column :user_list, :text
      t.timestamps
    end
  end
end