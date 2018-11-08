RedmineApp::Application.routes.draw do
  resources :custom_reminders do
    collection do
      get :schedule_custom_reminder
    end
  end
end