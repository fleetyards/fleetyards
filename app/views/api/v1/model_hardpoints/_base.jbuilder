# frozen_string_literal: true

json.id hardpoint.id
json.type hardpoint.hardpoint_type
json.group hardpoint.group

json.source hardpoint.source

json.category hardpoint.category
json.category_label hardpoint.category_label
json.sub_category hardpoint.sub_category
json.sub_category_label hardpoint.sub_category_label

json.size hardpoint.size
json.size_label hardpoint.size_label.to_s

json.name hardpoint.name
json.loadout_identifier hardpoint.loadout_identifier

json.key hardpoint.key

json.details hardpoint.details
json.mount hardpoint.mount
json.item_slots hardpoint.item_slots

json.component do
  json.partial! "api/v1/components/base", component: hardpoint.component if hardpoint.component.present?
end
json.component nil if hardpoint.component.blank?

json.loadouts do
  json.array! hardpoint.model_hardpoint_loadouts, partial: "api/v1/model_hardpoint_loadouts/base", as: :loadout
end

json.partial! "api/shared/dates", record: hardpoint
