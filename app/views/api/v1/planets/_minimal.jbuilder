# frozen_string_literal: true

json.cache! ['v1', planet] do
  json.partial! 'api/v1/planets/base', planet: planet
  json.moons do
    json.array! planet.moons.order(:name), partial: 'api/v1/planets/base', as: :planet
  end
  json.starsystem do
    json.partial! 'api/v1/starsystems/base', starsystem: planet.starsystem
  end
  json.partial! 'api/shared/dates', record: planet
end
