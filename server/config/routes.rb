Rails.application.routes.draw do
  resources :schedules, only: [:show, :create] do
    member do
      post :confirm
      post :reject
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
