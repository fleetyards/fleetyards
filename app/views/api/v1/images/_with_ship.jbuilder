# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', image] do
  json.id image.id
  json.name image.name
  json.ship do
    json.partial! 'api/v1/ships/show', ship: image.gallery if image.gallery.present?
  end
  json.partial! 'api/shared/dates', record: image
end
