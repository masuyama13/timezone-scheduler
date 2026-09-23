Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "world_clock/timeline", to: "world_clock/timelines#show", as: :world_clock_timeline
  get "world_clock/time_resolution", to: "world_clock/time_resolutions#show", as: :world_clock_time_resolution
  post "world_clock/candidate_review", to: "world_clock/candidate_reviews#create", as: :world_clock_candidate_review
  resources :events, param: :public_token, only: [ :create, :show, :destroy ]
  post "events/:public_token/responses", to: "events/responses#create", as: :event_responses
  patch "events/:public_token/responses/:response_id", to: "events/responses#update", as: :event_response
  delete "events/:public_token/responses/:response_id", to: "events/responses#destroy"

  root "world_clock#index"
end
