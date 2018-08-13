# frozen_string_literal: true

json.total @count.total
json.classifications do
  json.array! @count.classifications, partial: 'api/v1/vehicles/classification_count', as: :classification_count
end
json.metrics do
  json.total_money @count.metrics[:total_money]
  json.total_min_crew @count.metrics[:total_min_crew]
  json.total_max_crew @count.metrics[:total_max_crew]
  json.total_cargo @count.metrics[:total_cargo]
end
