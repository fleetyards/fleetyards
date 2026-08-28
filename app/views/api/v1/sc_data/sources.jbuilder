# frozen_string_literal: true

json.items do
  json.array! @sources do |source|
    json.environment source.environment
    json.version source.version
    json.default source.default?
  end
end
