# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "portfolio", to: "portfolio#show"
      get "rewards", to: "rewards#index"
      resources :networks, only: :index
      resources :stake_operations, only: %i[index show create]
      post "sync/rewards", to: "sync#rewards"
      get "sync/runs/:id", to: "sync#show", as: :sync_run
    end
  end

  get "health", to: proc { [ 200, { "Content-Type" => "application/json" }, [ '{"status":"ok"}' ] ] }

  match "*unmatched", to: "errors#not_found", via: :all
end
