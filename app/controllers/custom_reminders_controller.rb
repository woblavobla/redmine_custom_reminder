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
      if params.key?(:commit) && @workflow.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(custom_reminders_path) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def edit; end

  private

  def find_custom_reminder
    @reminder = CustomReminder.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def params_for_actions
    params.require(:custom_workflow).permit(:name, :description,
                                            :interval, :executed_at,
                                            :user_list_script, :condition_script,
                                            :active,
                                            project_ids: [])
  end
end
