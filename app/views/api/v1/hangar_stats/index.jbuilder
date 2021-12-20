# frozen_string_literal: true

json.total @quick_stats.total
json.classifications do
  json.array! @quick_stats.classifications, partial: 'api/v1/vehicles/classification_quick_stats', as: :classification_quick_stats
end
json.groups do
  json.array! @quick_stats.groups, partial: 'api/v1/vehicles/group_quick_stats', as: :group_quick_stats
end
json.metrics do
  json.total_money @quick_stats.metrics[:total_money]
  json.total_min_crew @quick_stats.metrics[:total_min_crew]
  json.total_max_crew @quick_stats.metrics[:total_max_crew]
  json.total_cargo @quick_stats.metrics[:total_cargo]
end
