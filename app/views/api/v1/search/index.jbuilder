# frozen_string_literal: true

json.groups @groups do |group|
  json.type group.type
  json.items group.items do |result|
    json.type result.type
    json.name result.name
    json.slug result.slug
    json.detail result.detail
    if result.appearance
      json.appearance do
        json.kind result.appearance.kind
        json.color result.appearance.color
        json.body_type result.appearance.body_type
        json.flare result.appearance.flare
      end
    end
    if result.image
      json.image do
        json.partial! "api/v1/shared/file", record: result.image.record, attr: result.image.name
      end
    end
  end
end
