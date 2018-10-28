# frozen_string_literal: true

json.cache! ['v1', starsystem] do
  json.partial! 'api/v1/starsystems/base', starsystem: starsystem
  json.celestialObjects do
    json.array! starsystem.celestial_objects.order(designation: :asc).visible.main.order(:designation), partial: 'api/v1/celestial_objects/base', as: :celestial_object
  end
  json.partial! 'api/shared/dates', record: starsystem
end
