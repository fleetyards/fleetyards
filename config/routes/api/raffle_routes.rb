# frozen_string_literal: true

resources :raffles, only: %i[show] do
  get :current, on: :collection
  member do
    get :entrants
  end
  resource :entry, controller: "raffle_entries", only: %i[create destroy]
end

# The link in a winner's claim mail. No sign-in: the mail reached the address
# the win is for, and the token is the proof of it.
resource :raffle_claim, path: "raffle-claims", only: %i[create]
