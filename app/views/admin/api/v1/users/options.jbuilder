# frozen_string_literal: true

json.items @users do |user|
  json.partial! "admin/api/v1/users/option", user: user
end
json.partial! "api/shared/meta", result: @users
