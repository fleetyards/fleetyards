# frozen_string_literal: true

resources :raffles, only: %i[show] do
  get :current, on: :collection
  # Shows a draft as well, to whoever holds the link. No sign-in, so it can go
  # to someone without an account here.
  get "preview/:token", on: :collection, action: :preview, as: :preview
  member do
    get :entrants
  end
  resource :entry, controller: "raffle_entries", only: %i[create destroy]
end

# The link in a winner's claim mail. No sign-in: the mail reached the address
# the win is for, and the token is the proof of it.
resource :raffle_claim, path: "raffle-claims", only: %i[create]

resources :my_raffle_entries, path: "my-raffle-entries", only: %i[index]
