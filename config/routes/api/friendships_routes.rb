# frozen_string_literal: true

# Addressed by the *other* party's username, which is what a friendship is
# identified by from either end -- the row's own id is an implementation
# detail nobody outside the API has.
#
# One resource rather than a second one for requests. A request and a
# friendship are the same row in two states, and splitting them would give the
# accept endpoint two possible addresses for one thing. `q[state]` filters.
resources :friendships, path: "friends", param: :username, only: %i[index show create destroy] do
  member do
    put :accept
    put :decline
    put :ignore
  end
end
