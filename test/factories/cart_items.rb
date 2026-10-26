# frozen_string_literal: true

FactoryBot.define do
  factory :cart_item do
    user
    item { association :commodity }
    quantity { 1 }
  end
end
