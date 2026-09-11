# frozen_string_literal: true

json.partial! "api/v1/models/model", model: @model, extended: true

# Outside the cached fragment above on purpose: this answer depends on other
# models' docks, and the fragment's key knows only about this one.
json.carried_by @model.carried_by_with_docks do |entry|
  carrier = entry[:carrier]

  json.slug carrier.slug
  json.name carrier.name
  json.dock_type entry[:dock].dock_type

  # Absent rather than empty when the carrier has no picture: MediaFile requires
  # four fields, and the panel falls back on its own.
  if carrier.store_image.attached?
    json.store_image do
      json.partial! "api/v1/shared/file", record: carrier, attr: :store_image
    end
  end
end
