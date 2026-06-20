# frozen_string_literal: true

json.items do
  json.array! @funding_goals, partial: "admin/api/v1/funding_goals/funding_goal", as: :funding_goal
end
json.partial! "api/shared/meta", result: @funding_goals
