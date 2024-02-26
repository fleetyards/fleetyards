# frozen_string_literal: true

json.items do
  json.array! @starsystems, partial: "api/v1/starsystems/starsystem", as: :starsystem
end
json.partial! "api/shared/meta", result: @starsystems
