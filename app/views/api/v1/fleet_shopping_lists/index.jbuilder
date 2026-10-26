# frozen_string_literal: true

json.array! @fleet_shopping_lists, partial: "api/v1/fleet_shopping_lists/fleet_shopping_list", as: :fleet_shopping_list
