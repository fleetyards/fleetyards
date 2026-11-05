# frozen_string_literal: true

json.partial! "api/v1/factions/faction", faction: @faction, mission_count: @faction.mission_count
json.description @faction.description
json.headquarters @faction.headquarters
json.founded @faction.founded
json.leadership @faction.leadership

json.ladders @faction.ladders do |ladder|
  awards = @awards.fetch(ladder.key, {})

  json.key ladder.key
  json.name ladder.name
  json.ceiling ladder.ceiling
  json.ranks ladder.ranks do |rank|
    json.name rank["name"]
    json.min_reputation rank["min_reputation"]
  end
  json.mission_count awards.fetch(:missions, 0)
  json.min_award awards[:min]
  json.max_award awards[:max]
end
