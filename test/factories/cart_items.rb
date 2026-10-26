# frozen_string_literal: true

FactoryBot.define do
  factory :cart do
    user
    sequence(:name) { |n| "List #{n}" }
    active { true }
  end

  factory :cart_item do
    # A user puts the line in their active list, as adding from a catalogue does.
    transient do
      user { nil }
    end

    cart { user ? Cart.active_for!(user) : association(:cart) }
    item { association :commodity }
    quantity { 1 }
  end
end
