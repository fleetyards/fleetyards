# frozen_string_literal: true

json.items do
  json.array! @hangar_pledge_items, partial: "api/v1/hangar_pledge_items/hangar_pledge_item", as: :hangar_pledge_item
end
json.partial! "api/shared/meta", result: @hangar_pledge_items
