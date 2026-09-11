# frozen_string_literal: true

resources :imports, only: %i[index show] do
  member do
    put :cancel
  end
end
