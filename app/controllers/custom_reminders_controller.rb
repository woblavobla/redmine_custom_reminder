require_relative '../jobs/custom_reminders_job'

class CustomRemindersController < ApplicationController
  layout 'admin'
  before_action :require_admin
  before_action :find_custom_reminder, only: %i[show edit update destroy export]

  def index
    @reminders = CustomReminder.all.to_a
  end

  def new
    @reminder = CustomReminder.new
    respond_to(&:html)
  end

  def create
    @reminder = CustomReminder.new(params_for_actions)
    respond_to do |format|
      if params.key?(:commit) && @reminder.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(custom_reminders_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      @reminder.assign_attributes(params_for_actions)
      if params.key?(:commit) && @reminder.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(custom_reminders_path) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @reminder.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to(custom_reminders_path) }
    end
  end

  def edit; end

  def export
    send_data @reminder.export_as_yaml, filename: "#{@reminder.name}.yml", type: :yml
  end

  def import
    yml = params[:file].read
    begin
      @reminder = CustomReminder.import_from_yml(yml)
      @reminder.active = false
      if @reminder.save
        flash[:notice] = l(:notice_custom_reminder_import)
      else
        flash[:error] = @reminder.errors.full_messages.to_sentence
      end
    rescue StandardError => e
      Rails.logger.warn "Custom reminder import error: #{e.message}\n #{e.backtrace.join("\n ")}"
      flash[:error] = l(:error_custom_reminder_import)
    end
    respond_to do |format|
      format.html { redirect_to(custom_reminders_path) }
    end
  end

  def schedule_custom_reminder
    CustomRemindersJob.perform_now(params)
    redirect_to custom_reminders_path
  end

  private

  def find_custom_reminder
    @reminder = CustomReminder.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def params_for_actions
    params.require(:custom_reminder).permit(:name, :description,
                                            :executed_at, :notification_recipient,
                                            :user_scope_script, :trigger_script,
                                            :active, project_ids: [], send_days: [])
  end
end
