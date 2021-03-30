# frozen_string_literal: true

json.cache! ['v1', equipment] do
  json.partial! 'api/v1/equipment/base', equipment: equipment
  json.partial! 'api/shared/dates', record: equipment
end
