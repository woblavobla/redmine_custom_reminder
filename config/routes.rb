RedmineApp::Application.routes.draw do
  resources :custom_reminders, param: :id do
    collection do
      get :schedule_custom_reminder
      post :import
    end
    member do
      get :export
    end
  end
end