# frozen_string_literal: true

# What an allied fleet sees of a member. A handful of fields, and adding one is
# a deliberate act -- this partial exists precisely so that the roster cannot
# inherit a field somebody adds to the fleet's own member payload.
#
# A member who has set `hide_owner` keeps their row and loses their name, the
# same way they already do on a vehicle they own. The roster stays honest about
# how large the fleet is without attaching a name to every place in it.
json.id member.id

if member.user.hide_owner?
  json.hidden true
else
  json.hidden false
  json.username member.user.username
  json.display_name member.user.display_name if member.user.display_name.present?
  json.avatar do
    json.partial! "api/v1/shared/file", record: member.user, attr: :avatar
  end
end

json.role member.fleet_role&.name
