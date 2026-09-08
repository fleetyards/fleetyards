# frozen_string_literal: true

json.items do
  json.array! @builds do |build|
    json.environment build.environment
    json.version build.version
    json.default build.default?
  end
end
