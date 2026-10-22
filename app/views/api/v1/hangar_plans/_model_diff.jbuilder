# frozen_string_literal: true

json.model do
  json.partial! "api/v1/hangar_plans/model", model: diff.model
end
json.left_count diff.left_count
json.right_count diff.right_count
json.change diff.change
