# frozen_string_literal: true

json.items do
  json.array! @results, partial: "api/v1/search/search", as: :result
end
json.partial! "api/shared/meta", result: @results
