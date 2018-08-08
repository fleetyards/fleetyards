# frozen_string_literal: true

json.id user.id
json.email user.email
json.username user.username
json.avatar user.avatar(48)
json.is_admin user.admin?
json.rsi_handle user.rsi_handle
json.sale_notify user.sale_notify
json.fleets user.rsi_orgs
json.rsi_verified user.rsi_verified
json.created_at user.created_at
json.updated_at user.updated_at
