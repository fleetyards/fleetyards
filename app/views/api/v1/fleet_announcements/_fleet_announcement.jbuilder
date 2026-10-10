# frozen_string_literal: true

json.id fleet_announcement.id
json.body fleet_announcement.body
json.expires_at fleet_announcement.expires_at
json.created_at fleet_announcement.created_at
json.updated_at fleet_announcement.updated_at

if fleet_announcement.author.present?
  json.author do
    json.id fleet_announcement.author.id
    json.username fleet_announcement.author.username
    if fleet_announcement.author.avatar.attached?
      json.avatar do
        json.partial! "api/v1/shared/file", record: fleet_announcement.author, attr: :avatar
      end
    end
  end
else
  json.author nil
end
