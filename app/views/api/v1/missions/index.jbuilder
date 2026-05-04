# frozen_string_literal: true

json.items do
  json.array! @missions, partial: "api/v1/missions/mission", as: :mission
end
json.partial! "api/shared/meta", result: @missions
