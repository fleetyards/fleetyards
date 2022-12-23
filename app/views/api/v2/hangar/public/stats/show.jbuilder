# frozen_string_literal: true

json.total @quick_stats.total
json.classifications do
  json.array! @quick_stats.classifications, partial: 'api/v2/hangar/stats/classification', as: :classification_quick_stats
end
json.groups do
  json.array! @quick_stats.groups, partial: 'api/v2/hangar/stats/group', as: :group_quick_stats
end
