# frozen_string_literal: true

# The trimmed model a ship spot points at: enough to name the ship, show its
# cover and read its crew, without the rest of a model payload. Shared because a
# spot can name one model or list several, on a mission and on an event alike —
# four copies of this block before it lived here.
json.id model.id
json.name model.name
json.slug model.slug
json.min_crew model.min_crew
json.max_crew model.max_crew

image_attr = if model.store_image.attached?
  :store_image
elsif model.angled_view.attached?
  :angled_view
elsif model.fleetchart_image.attached?
  :fleetchart_image
end

if image_attr
  json.image do
    json.partial! "api/v1/shared/file", record: model, attr: image_attr
  end
else
  json.image nil
end
