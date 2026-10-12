# frozen_string_literal: true

resources :vehicles, only: [] do
  resources :log_entries, path: "log-entries", controller: "vehicle_log_entries", only: %i[index create update destroy]
end
