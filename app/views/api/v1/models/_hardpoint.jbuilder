# encoding: utf-8
# frozen_string_literal: true

json.id hardpoint.id
json.type hardpoint.hardpoint_type
json.class hardpoint.component_class
json.size hardpoint.size
json.quantity hardpoint.quantity
json.mounts hardpoint.mounts
json.details hardpoint.details
json.category hardpoint.category
json.component do
  json.partial! 'api/v1/models/component', component: hardpoint.component if hardpoint.component.present?
end
