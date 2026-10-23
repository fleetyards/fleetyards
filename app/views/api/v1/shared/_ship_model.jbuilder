# frozen_string_literal: true

# The trimmed model a ship spot points at: enough to name the ship, show its
# cover and read its crew, without the rest of a model payload. Shared because a
# spot can name one model or list several, on a mission and on an event alike —
# four copies of this block before it lived here.
json.id model.id
json.name model.name
json.slug model.slug
json.crew model.crew

json.partial! "api/v1/shared/ship_model_image", model: model
