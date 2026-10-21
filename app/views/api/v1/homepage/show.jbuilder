# frozen_string_literal: true

json.search_suggestions @search_suggestions

if @featured_ship
  json.featured_ship do
    json.name @featured_ship.name
    json.slug @featured_ship.slug
    json.manufacturer_name @featured_ship.manufacturer&.name
    preview = @featured_ship.preview_view
    if preview
      json.image do
        json.partial! "api/v1/shared/file", record: @featured_ship, attr: preview.name
      end
    end
  end
end
