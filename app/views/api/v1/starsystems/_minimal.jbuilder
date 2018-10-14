# frozen_string_literal: true

json.cache! ['v1', starsystem] do
  json.partial! 'api/v1/starsystems/base', starsystem: starsystem
  json.planets do
    json.array! starsystem.planets.main.order(:name), partial: 'api/v1/planets/base', as: :planet
  end
  json.partial! 'api/shared/dates', record: starsystem
end
