# frozen_string_literal: true

json.id vehicle_loadout.id
json.name vehicle_loadout.name
json.active vehicle_loadout.active
json.erkul_url vehicle_loadout.erkul_url
json.spviewer_url vehicle_loadout.spviewer_url

json.hardpoints do
  json.array! vehicle_loadout.vehicle_loadout_hardpoints do |vlh|
    json.id vlh.id
    json.model_hardpoint_id vlh.model_hardpoint_id

    json.hardpoint do
      json.partial! "api/v1/model_hardpoints/base", hardpoint: vlh.model_hardpoint
    end

    json.component do
      json.partial! "api/v1/components/base", component: vlh.component if vlh.component.present?
    end
    json.component nil if vlh.component.blank?
  end
end

json.partial! "api/shared/dates", record: vehicle_loadout
