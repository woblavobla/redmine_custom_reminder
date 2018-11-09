class CustomRemindersController < ApplicationController
  layout 'admin'
  before_action :require_admin
  before_action :find_custom_reminder, only: %i[show edit update destroy]

  def index
    @reminders = CustomReminder.all.to_a
  end

  def new
    @reminder = CustomReminder.new
    respond_to do |format|
      format.html
    end
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

  def schedule_custom_reminder
    CustomRemindersEmailNotificationJob.perform_now(params)
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
                                            :interval, :executed_at,
                                            :trigger_type, :notification_recipient,
                                            :user_scope_script, :trigger_script,
                                            :active,
                                            project_ids: [])
  end
end
