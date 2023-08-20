# frozen_string_literal: true

json.id loadout.id
json.name loadout.name
json.component do
  json.partial! "api/v1/components/base", component: loadout.component if loadout.component.present?
end
json.component nil if loadout.component.blank?

json.partial! "api/shared/dates", record: loadout
