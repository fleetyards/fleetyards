# frozen_string_literal: true

# See `api/v1/friendships/_base` -- the same two per-party answers, from a
# fleet's side rather than a person's.
other = alliance.other_party_for(party)

json.id alliance.id
json.state alliance.state_for(party)
json.direction alliance.requester_id == party&.id ? "outgoing" : "incoming"

json.fleet do
  json.id other&.id
  json.name other&.name
  json.slug other&.slug
  json.logo do
    json.partial! "api/v1/shared/file", record: other, attr: :logo
  end
end

json.accepted_at alliance.accepted_at&.utc&.iso8601
json.partial! "api/shared/dates", record: alliance
