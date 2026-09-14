# frozen_string_literal: true

json.items do
  json.array! @relationships, partial: "api/v1/fleet_alliances/base", as: :alliance, locals: {party: acting_party}
end
json.partial! "api/shared/meta", result: @relationships
