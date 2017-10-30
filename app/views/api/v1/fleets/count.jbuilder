# frozen_string_literal: true

json.total @count.total
json.classifications do
  json.array! @count.classifications, partial: 'api/v1/vehicles/classification_count', as: :classification_count
end
