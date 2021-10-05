# frozen_string_literal: true

json.cache! ['v1', user] do
  json.username user.username
  json.avatar user.avatar.small.url
  json.rsi_handle user.rsi_handle
  json.discord user.discord
  json.youtube user.youtube
  json.twitch user.twitch
  json.guilded user.guilded
  json.homepage user.homepage
  json.public_hangar_loaners user.public_hangar_loaners
end
