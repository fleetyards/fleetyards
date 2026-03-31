# frozen_string_literal: true

json.id hardpoint.id
json.name hardpoint.sc_name
json.type hardpoint.category
json.group hardpoint.group
json.source hardpoint.source
json.category hardpoint.category
json.category_label hardpoint.category
json.sub_category nil
json.sub_category_label nil
json.size hardpoint.max_size
json.size_label hardpoint.max_size.to_s
json.key hardpoint.group_key
json.loadout_identifier nil
json.details hardpoint.details
json.mount nil
json.item_slots nil
json.model_id hardpoint.parent_id

json.component do
  json.partial! "api/v1/components/base", component: hardpoint.component if hardpoint.component.present?
end
json.component nil if hardpoint.component.blank?

json.loadouts do
  json.array! hardpoint.hardpoints do |child|
    json.id child.id
    json.name child.sc_name
    json.model_hardpoint_id hardpoint.id
    json.component do
      json.partial! "api/v1/components/base", component: child.component if child.component.present?
    end
    json.component nil if child.component.blank?
    json.partial! "api/shared/dates", record: child
  end
end

json.partial! "api/shared/dates", record: hardpoint
