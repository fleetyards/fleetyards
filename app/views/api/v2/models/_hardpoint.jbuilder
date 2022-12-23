# frozen_string_literal: true

json.id hardpoint.id
json.type hardpoint.hardpoint_type
json.group hardpoint.group
json.category hardpoint.category
json.category_label hardpoint.category_label
json.size hardpoint.size
json.size_label hardpoint.size_label

json.name hardpoint.name
json.loadout_identifier hardpoint.loadout_identifier

json.key hardpoint.key

json.details hardpoint.details
json.mount hardpoint.mount
json.item_slots hardpoint.item_slots

json.component do
  json.partial! 'api/v1/models/component', component: hardpoint.component if hardpoint.component.present?
end
json.component nil if hardpoint.component.blank?

json.loadouts do
  json.array! hardpoint.model_hardpoint_loadouts, partial: 'api/v1/models/hardpoint_loadout', as: :loadout
end
