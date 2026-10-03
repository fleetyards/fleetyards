# frozen_string_literal: true

json.total_count @people.total_count
json.people @people.entries do |entry|
  user = entry.user

  json.id user.id
  json.username user.username
  json.avatar do
    json.partial! "api/v1/shared/file", record: user, attr: :avatar
  end

  online = online_status_for(user)
  json.online online unless online.nil?

  json.partial! "api/v1/locations/linked", key: :current_location, location: user.current_location
  json.friend entry.friend
  json.fleets entry.fleets do |fleet|
    json.id fleet.id
    json.slug fleet.slug
    json.name fleet.name
  end
end
