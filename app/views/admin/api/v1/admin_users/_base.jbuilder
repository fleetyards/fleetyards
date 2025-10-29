# frozen_string_literal: true

json.id admin_user.id
json.email admin_user.email
json.username admin_user.username
json.two_factor_required admin_user.otp_required_for_login?
unless admin_user.otp_required_for_login?
  json.two_factor_qr_code_url qrcode_api_v1_otp_url
  json.two_factor_provisioning_url admin_user.otp_provisioning_uri(admin_user.email, issuer: Rails.configuration.app.name)
end
json.resource_access admin_user.resource_access || []
json.super_admin admin_user.super_admin
json.partial! "api/shared/dates", record: admin_user
