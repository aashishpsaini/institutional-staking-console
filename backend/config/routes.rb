# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "portfolio", to: "portfolio#show"
      get "rewards", to: "rewards#index"
      resources :stake_operations, only: %i[index create]
      post "sync/rewards", to: "sync#rewards"
    end
  end

  get "health", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }
end
