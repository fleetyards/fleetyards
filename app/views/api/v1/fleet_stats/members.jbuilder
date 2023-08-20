# frozen_string_literal: true

json.total @quick_stats.total
json.metrics do
  json.total_admins @quick_stats.metrics[:total_admins]
  json.total_officers @quick_stats.metrics[:total_officers]
  json.total_members @quick_stats.metrics[:total_members]
end
