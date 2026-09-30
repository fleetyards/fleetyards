# frozen_string_literal: true

resources :push_subscriptions, path: "push-subscriptions", only: %i[index create destroy] do
  put :touch, on: :member
end
