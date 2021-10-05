# frozen_string_literal: true

json.cache! ['v1', user] do
  json.id user.id
  json.email user.email
  json.unconfirmed_email user.unconfirmed_email
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
  json.public_hangar_url user.public_hangar_url
  json.public_hangar_loaners user.public_hangar_loaners
  json.two_factor_required user.otp_required_for_login?
  json.two_factor_qr_code_url qrcode_api_v1_two_factor_url unless user.otp_required_for_login?
  json.partial! 'api/shared/dates', record: user
end
