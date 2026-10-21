# frozen_string_literal: true

json.items do
  json.array! @missions do |mission|
    json.id mission.id

    json.mission do
      json.partial! "api/v1/game_missions/game_mission", mission:
    end

    json.wanted_blueprints @wanted_blueprints.fetch(mission.id, []) do |blueprint|
      json.id blueprint.id
      json.name blueprint.name
      json.slug blueprint.slug
    end
  end
end
json.partial! "api/shared/meta", result: @missions
