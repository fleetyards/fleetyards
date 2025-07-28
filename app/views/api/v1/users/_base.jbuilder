# frozen_string_literal: true

json.id user.id

json.username user.username

json.email user.email
json.unconfirmed_email user.unconfirmed_email if user.unconfirmed_email.present?

json.avatar user.avatar.small.url if user.avatar.present?

json.rsi_handle user.rsi_handle if user.rsi_handle.present?

json.discord user.discord if user.discord.present?
json.youtube user.youtube if user.youtube.present?
json.twitch user.twitch if user.twitch.present?
json.guilded user.guilded if user.guilded.present?
json.homepage user.homepage if user.homepage.present?

json.sale_notify user.sale_notify
json.public_hangar user.public_hangar
json.public_hangar_url user.public_hangar_url
json.public_hangar_loaners user.public_hangar_loaners
json.public_wishlist user.public_wishlist
json.public_wishlist_url user.public_wishlist_url
json.hide_owner user.hide_owner

json.two_factor_required user.otp_required_for_login?
unless user.otp_required_for_login?
  json.two_factor_qr_code_url qrcode_api_v1_otp_url
  json.two_factor_provisioning_url user.otp_provisioning_uri(user.email, issuer: Rails.configuration.app.name)
end

json.hangar_updated_at user.hangar_updated_at.utc.iso8601 if user.hangar_updated_at.present?

json.resource_access []

json.auth_connections user.omniauth_connections.pluck(:provider)

json.partial! "api/shared/dates", record: user
