# frozen_string_literal: true

json.items do
  json.array! @users, partial: "admin/api/v1/users/user", as: :user
end
json.partial! "api/shared/meta", result: @users
