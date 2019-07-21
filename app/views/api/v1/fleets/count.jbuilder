# frozen_string_literal: true

json.total @count.total
json.classifications do
  json.array! @count.classifications, partial: 'api/v1/vehicles/classification_quick_stats', as: :classification_quick_stats
end
json.models @count.models
