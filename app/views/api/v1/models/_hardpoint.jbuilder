# frozen_string_literal: true

json.id hardpoint.id
json.type hardpoint.hardpoint_type
json.size hardpoint.size
json.size_label hardpoint.size_label
json.quantity hardpoint.quantity
json.details hardpoint.details
json.category hardpoint.category
json.category_label hardpoint.category_label
json.group hardpoint.group
json.component do
  json.partial! 'api/v1/components/minimal', component: hardpoint.component if hardpoint.component.present?
end
json.component nil if hardpoint.component.blank?
