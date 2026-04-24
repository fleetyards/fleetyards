# frozen_string_literal: true

json.username user.username
json.avatar do
  json.partial! "api/v1/shared/file", record: user, attr: :avatar
end
json.rsi_handle user.rsi_handle
json.rsi_handle_verified user.rsi_handle_verified
json.citizenid_profile_url user.citizenid_profile_url if user.rsi_handle_verified?
json.discord user.discord
json.youtube user.youtube
json.twitch user.twitch
json.guilded user.guilded
json.homepage user.homepage
json.public_hangar_loaners user.public_hangar_loaners
json.public_hangar_stats user.public_hangar_stats
json.public_wishlist user.public_wishlist
