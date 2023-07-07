# frozen_string_literal: true

json.cache! ["v1", celestial_object] do
  json.partial!("api/v1/celestial_objects/base", celestial_object:)
  json.parent do
    json.null! if celestial_object.parent.blank?
    json.partial! "api/v1/celestial_objects/base", celestial_object: celestial_object.parent if celestial_object.parent.present?
  end
  json.moons do
    json.array! celestial_object.moons.visible.order(designation: :asc).visible.order(:name), partial: "api/v1/celestial_objects/base", as: :celestial_object
  end
  json.partial! "api/shared/dates", record: celestial_object
end
