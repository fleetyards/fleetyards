# frozen_string_literal: true

json.partial! "api/v1/locations/link", location: location

json.sc_key location.sc_key
json.game_type location.game_type

json.retired location.retired?

# How the in-game map shows the place, which is not always how it nests: Levski
# is drawn at system level under the Nyx star, and sits inside Delamar.
json.shown_on_starmap location.shown_on_starmap
json.shown_with_parent_only location.shown_with_parent_only
json.always_shown location.always_shown
json.quantum_travel_destination location.quantum_travel_destination

# Shown with the name wherever the name is not unique: there are two Outpost
# 54s on Aberdeen and 306 QV Logistics Stations in Nyx.
if location.parent
  json.parent do
    json.partial! "api/v1/locations/link", location: location.parent
  end
else
  json.parent nil
end

json.created_at location.created_at
json.updated_at location.updated_at
