# frozen_string_literal: true

json.id hardpoint.id
json.type hardpoint.hardpoint_type
json.class hardpoint.component_class
json.size hardpoint.size
json.quantity hardpoint.quantity
json.mounts hardpoint.mounts
json.details hardpoint.details
json.category hardpoint.category
json.default_empty hardpoint.default_empty
json.component do
  json.partial! 'api/v1/components/minimal', component: hardpoint.component if hardpoint.component.present?
end
json.component nil if hardpoint.component.blank?
