# frozen_string_literal: true

json.partial! 'api/shared/pagination_metadata', scope: @equipment, model: Equipment
json.items do
  json.array! @equipment, partial: 'api/v2/equipment/minimal', as: :equipment
end
