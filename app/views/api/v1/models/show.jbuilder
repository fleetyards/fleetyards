# frozen_string_literal: true

json.partial! "api/v1/models/model", model: @model, extended: true

# Outside the cached fragment above on purpose: this answer depends on other
# models' docks, and the fragment's key knows only about this one.
json.carried_by @model.carried_by_with_docks do |entry|
  carrier = entry[:carrier]

  json.slug carrier.slug
  json.name carrier.name
  json.dock_type entry[:dock].dock_type

  # How the ship gets in, when somebody has recorded it. Stated rather than
  # filtered on: a berth reachable only by tractor beam still takes the ship,
  # awkwardly, and that is a sentence for the reader rather than a condition.
  access_label = entry[:dock].access_label
  json.access_label access_label if access_label.present?

  # Present only for a berth a module brings, which is what makes the carrier
  # conditional rather than a fixture.
  module_name = entry[:dock].model_module_name
  json.module_name module_name if module_name.present?

  # Absent rather than empty when the carrier has no picture: MediaFile requires
  # four fields, and the panel falls back on its own.
  if carrier.store_image.attached?
    json.store_image do
      json.partial! "api/v1/shared/file", record: carrier, attr: :store_image
    end
  end
end
