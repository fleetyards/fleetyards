# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_shopping_list do
    fleet
    sequence(:name) { |n| "Kit #{n}" }
    visibility { :members_only }
  end

  factory :fleet_shopping_list_item do
    fleet_shopping_list
    item { association :commodity }
    quantity { 1 }
  end
end
