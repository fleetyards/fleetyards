# frozen_string_literal: true

json.from { json.partial! "api/v1/sc_data/build", build: @from }
json.to { json.partial! "api/v1/sc_data/build", build: @to }

json.code @code

json.items do
  json.array! @results.to_a do |(catalogue, result)|
    json.catalogue catalogue
    json.recorded result.recorded
    json.counts result.counts
  end
end
