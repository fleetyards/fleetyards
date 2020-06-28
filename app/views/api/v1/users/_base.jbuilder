# frozen_string_literal: true

json.cache! ['v1', user] do
  json.id user.id
  json.email user.email
  json.username user.username
  json.avatar user.avatar.small.url
  json.rsi_handle user.rsi_handle
  json.discord user.discord
  json.youtube user.youtube
  json.twitch user.twitch
  json.guilded user.guilded
  json.homepage user.homepage
  json.sale_notify user.sale_notify
  json.public_hangar user.public_hangar
  json.partial! 'api/shared/dates', record: user
end
