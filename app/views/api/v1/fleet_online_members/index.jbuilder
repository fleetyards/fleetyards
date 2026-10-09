# frozen_string_literal: true

json.total_count @total_count
json.items do
  json.array! @members do |membership|
    json.username membership.user.username
    json.nickname membership.nickname
    json.friend @friend_ids.include?(membership.user_id)
    if membership.user.avatar.attached?
      json.avatar do
        json.partial! "api/v1/shared/file", record: membership.user, attr: :avatar
      end
    else
      json.avatar nil
    end
  end
end
