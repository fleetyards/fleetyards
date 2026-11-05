# frozen_string_literal: true

json.groups @groups do |group|
  json.type group.type
  json.has_more group.has_more
  json.items group.items do |result|
    json.type result.type
    json.name result.name
    json.slug result.slug
    json.detail result.detail
    json.online result.online
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

if @search_fleet
  json.fleet do
    json.name @search_fleet.name
    json.slug @search_fleet.slug
    if @search_fleet.logo.attached?
      json.logo do
        json.partial! "api/v1/shared/file", record: @search_fleet, attr: :logo
      end
    end
  end
end
