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
    # PUT rather than DELETE for the destructive one: the selection travels in
    # the body, and a DELETE with a body is refused by enough proxies and
    # clients to not be worth it. `vehicles#destroy_bulk` made the same call.
    put "read-bulk", to: "notifications#read_bulk"
    put "unread-bulk", to: "notifications#unread_bulk"
    put "archive-bulk", to: "notifications#archive_bulk"
    put "unarchive-bulk", to: "notifications#unarchive_bulk"
    put "destroy-bulk", to: "notifications#destroy_bulk"
  end
end
