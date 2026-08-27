# frozen_string_literal: true

resources :notifications, only: %i[index destroy] do
  member do
    put :read
    put :unread
    put :archive
    put :unarchive
  end
  collection do
    get "unread-count", to: "notifications#unread_count"
    put "read-all", to: "notifications#read_all"
    delete "destroy-all", to: "notifications#destroy_all"
  end
end
