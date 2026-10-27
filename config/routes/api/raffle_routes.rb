# frozen_string_literal: true

resources :raffles, only: %i[index show] do
  member do
    get :entrants
    post :claim
    get :code
  end
  resource :entry, controller: "raffle_entries", only: %i[create destroy]
end
