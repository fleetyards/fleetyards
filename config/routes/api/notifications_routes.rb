# frozen_string_literal: true

resources :notifications, only: %i[index destroy] do
  member do
    put :read
  end
  collection do
    put "read-all", to: "notifications#read_all"
    delete "destroy-all", to: "notifications#destroy_all"
  end
end
