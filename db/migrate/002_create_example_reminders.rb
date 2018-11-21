class CreateExampleReminders < ActiveRecord::Migration[5.2]
  def change
    CustomReminder.create!(name: 'Уведомление за 1 день до срока завершения задачи', active: false, notification_recipient: -3, description: <<~EOD, trigger_script: <<~EOS)
      Уведомляет пользователей о задачах у которых истекает срок завершения.
    EOD
      cur_date = Date.today
      Issue.open.where(project: projects).each do |issue|
        issues_list << issue if issue.due_date == cur_date + 1
      end
    EOS
    CustomReminder.create!(name: 'Уведомление о задачах в стагнации', active: false, notification_recipient: -3, description: <<~EOD, trigger_script: <<~EOS)
      Уведомление о задачах в которых не было изменений и обновлений в течении 7 дней.
    EOD
      cur_date = Date.today
      Issue.open.where(project: projects).each do |issue|
        issues_list << issue if issue.updated_on < 7.day.until(cur_date)
      end
    EOS
  end
end
