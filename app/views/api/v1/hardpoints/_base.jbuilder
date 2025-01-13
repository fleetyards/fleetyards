# frozen_string_literal: true

json.id hardpoint.id
json.name hardpoint.sc_name

json.group_key hardpoint.group_key
json.matrix_key hardpoint.matrix_key

json.group hardpoint.group
json.source hardpoint.source

json.min_size hardpoint.min_size
json.max_size hardpoint.max_size

json.types hardpoint.types

json.category hardpoint.category

json.details hardpoint.details

json.component do
  json.partial! "api/v1/components/base", component: hardpoint.component if hardpoint.component.present?
end

json.hardpoints do
  json.array! hardpoint.hardpoints, partial: "api/v1/hardpoints/base", as: :hardpoint
end

json.partial! "api/shared/dates", record: hardpoint
