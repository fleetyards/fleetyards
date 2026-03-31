# frozen_string_literal: true

json.items do
  json.array! @admin_users, partial: "admin/api/v1/admin_users/admin_user", as: :admin_user
end
json.partial! "api/shared/meta", result: @admin_users
