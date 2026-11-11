# frozen_string_literal: true

json.partial! "api/v1/users/user", user: @user

# Outside the cached user: the hangar sync writes it without touching the user.
json.rsi_store_credit @user.rsi_store_credit&.to_f
