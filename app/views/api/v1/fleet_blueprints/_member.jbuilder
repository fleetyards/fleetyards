# frozen_string_literal: true

json.user_id membership.user_id
json.username membership.user.username
json.nickname membership.nickname
json.avatar do
  json.partial! "api/v1/shared/file", record: membership.user, attr: :avatar
end
