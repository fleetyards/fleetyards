# frozen_string_literal: true

json.partial! "api/v1/commodities/commodity", commodity: @commodity

# Outside the cached fragment: its key is this row, and a raw form retargeting
# its refinement changes only that other row.
json.refined_from @refined_from do |source|
  json.id source.id
  json.name source.name
  json.slug source.slug
end
