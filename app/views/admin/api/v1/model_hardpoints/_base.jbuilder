# frozen_string_literal: true

json.id model_hardpoint.id
json.name model_hardpoint.name
json.type model_hardpoint.hardpoint_type
json.group model_hardpoint.group
json.source model_hardpoint.source
json.category model_hardpoint.category
json.category_label model_hardpoint.category_label
json.sub_category model_hardpoint.sub_category
json.sub_category_label model_hardpoint.sub_category_label
json.size model_hardpoint.size
json.size_label model_hardpoint.size_label.to_s
json.key model_hardpoint.key
json.loadout_identifier model_hardpoint.loadout_identifier
json.details model_hardpoint.details
json.mount model_hardpoint.mount
json.item_slots model_hardpoint.item_slots
json.model_id model_hardpoint.model_id

json.component do
  json.partial! "api/v1/components/base", component: model_hardpoint.component if model_hardpoint.component.present?
end
json.component nil if model_hardpoint.component.blank?

json.loadouts do
  json.array! model_hardpoint.model_hardpoint_loadouts, partial: "api/v1/model_hardpoint_loadouts/base", as: :loadout
end

json.partial! "api/shared/dates", record: model_hardpoint
