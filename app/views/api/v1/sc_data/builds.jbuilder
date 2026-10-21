# frozen_string_literal: true

json.items do
  json.array! @builds do |build|
    json.environment build.environment
    json.version build.version
    json.default build.default?
    json.loading_screens @loading_screens.fetch(build.version, []) do |screen|
      json.partial! "api/v1/shared/file", record: screen, attr: :image
    end
  end
end
