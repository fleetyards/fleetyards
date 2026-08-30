# frozen_string_literal: true

json.items do
  json.array! @versions, partial: "admin/api/v1/versions/version", as: :version
end
json.partial! "api/shared/meta", result: @versions
