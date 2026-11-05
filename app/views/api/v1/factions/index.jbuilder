# frozen_string_literal: true

json.array! @factions do |faction|
  json.partial! "api/v1/factions/faction", faction:, mission_count: @mission_counts.fetch(faction.sc_key, 0)
end
