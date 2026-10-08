# frozen_string_literal: true

FactoryBot.define do
  factory :dock_capacity do
    dock
    ladder { :ship }
    size { "small" }
    quantity { 1 }
    display { false }
  end
end
