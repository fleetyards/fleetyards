# frozen_string_literal: true

json.id mission_ship.id
json.mission_team_id mission_ship.mission_team_id
json.title mission_ship.title
json.display_title mission_ship.display_title
json.description mission_ship.description
json.position mission_ship.position
json.strict mission_ship.strict?

if mission_ship.model.present?
  json.model do
    json.id mission_ship.model.id
    json.name mission_ship.model.name
    json.slug mission_ship.model.slug

    image_attr = if mission_ship.model.store_image.attached?
      :store_image
    elsif mission_ship.model.angled_view.attached?
      :angled_view
    elsif mission_ship.model.fleetchart_image.attached?
      :fleetchart_image
    end

    if image_attr
      json.image do
        json.partial! "api/v1/shared/file", record: mission_ship.model, attr: image_attr
      end
    else
      json.image nil
    end
  end
else
  json.model nil
end

json.filters do
  json.classification mission_ship.classification
  json.focus mission_ship.focus
  json.min_size mission_ship.min_size
  json.max_size mission_ship.max_size
  json.min_crew mission_ship.min_crew
  json.min_cargo mission_ship.min_cargo&.to_f
end

json.slots do
  json.array! mission_ship.mission_slots,
    partial: "api/v1/mission_slots/mission_slot",
    as: :mission_slot
end
