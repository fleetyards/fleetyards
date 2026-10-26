# frozen_string_literal: true

json.id fleet_shopping_list.id
json.name fleet_shopping_list.name
json.description fleet_shopping_list.description
json.visibility fleet_shopping_list.visibility
json.lines_count fleet_shopping_list.has_attribute?(:lines_count) ? fleet_shopping_list.lines_count : fleet_shopping_list.fleet_shopping_list_items.size
json.items_count fleet_shopping_list.has_attribute?(:items_count) ? fleet_shopping_list.items_count : fleet_shopping_list.fleet_shopping_list_items.sum(:quantity)

json.fleet_squadrons do
  json.array! fleet_shopping_list.fleet_squadrons.sort_by { |squadron| [squadron.team? ? 1 : 0, squadron.rank] } do |squadron|
    json.id squadron.id
    json.name squadron.name
    json.slug squadron.slug
    json.color squadron.color
    json.team squadron.team

    if squadron.icon.attached?
      json.icon do
        json.partial! "api/v1/shared/file", record: squadron, attr: :icon
      end
    else
      json.icon nil
    end
  end
end

json.partial! "api/shared/dates", record: fleet_shopping_list
