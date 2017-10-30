# frozen_string_literal: true

json.id user.id
json.email user.email
json.username user.username
json.avatar user.avatar(48)
json.is_admin user.admin?
json.rsi_handle user.rsi_handle
json.sale_notify user.sale_notify
json.fleets user.fleets.map(&:sid)
json.pending_fleets user.pending_fleets.map(&:sid)
json.admin_fleets user.admin_fleets.map(&:sid)
json.created_at user.created_at
json.updated_at user.updated_at
