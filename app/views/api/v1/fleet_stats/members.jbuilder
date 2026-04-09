# frozen_string_literal: true

json.total @quick_stats.total
json.metrics do
  json.members_by_role @quick_stats.metrics[:members_by_role]
end
