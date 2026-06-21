# frozen_string_literal: true

json.cache! ["v1", funding_goal] do
  json.partial!("admin/api/v1/funding_goals/base", funding_goal:)
end
