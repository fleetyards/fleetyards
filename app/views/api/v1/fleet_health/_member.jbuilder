# frozen_string_literal: true

json.username membership.user.username
json.nickname membership.nickname
json.last_active_at membership.user.last_active_at
if membership.user.avatar.attached?
  json.avatar do
    json.partial! "api/v1/shared/file", record: membership.user, attr: :avatar
  end
else
  json.avatar nil
end
