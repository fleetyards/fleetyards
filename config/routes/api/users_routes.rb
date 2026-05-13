resources :users, only: [] do
  collection do
    post :signup
    post :confirm
    post "check-email"
    post "check-username"

    get :me
    put "me", to: "users#update"
    delete "me", to: "users#destroy"
    put "account", to: "users#update_account"

    get ":username", to: "public/users#show"
  end
end

namespace :me, defaults: {format: :json} do
  resource :calendar_subscription, path: "calendar/subscription", only: %i[show create destroy] do
    post :rotate
  end
  get "calendar/events.ics", to: "calendar_subscriptions#ics",
    as: :calendar_feed, defaults: {format: "ics"}, constraints: {format: "ics"}
end

namespace :public do
  resources :users, param: :username, only: %i[show]
end
