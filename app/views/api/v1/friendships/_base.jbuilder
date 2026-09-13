# frozen_string_literal: true

# `state` and `direction` are answers about one of the two parties rather than
# properties of the row. In particular a request the other side ignored reads
# as `pending` here, exactly as an unanswered one does -- see
# `PartyRelationship#state_for`.
other = friendship.other_party_for(party)

json.id friendship.id
json.state friendship.state_for(party)
json.direction (friendship.requester_id == party&.id) ? "outgoing" : "incoming"

json.user do
  json.id other&.id
  json.username other&.username
  json.avatar do
    json.partial! "api/v1/shared/file", record: other, attr: :avatar
  end
end

json.accepted_at friendship.accepted_at&.utc&.iso8601
json.partial! "api/shared/dates", record: friendship
