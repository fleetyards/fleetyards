# frozen_string_literal: true

json.items do
  json.array! @entries do |entry|
    json.username entry.display_username
    json.entered_at entry.created_at.utc.iso8601
  end
end
json.partial! "api/shared/meta", result: @entries
