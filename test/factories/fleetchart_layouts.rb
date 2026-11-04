# frozen_string_literal: true

FactoryBot.define do
  factory :fleetchart_layout do
    user
    sequence(:name) { |n| "Layout #{n}" }
  end
end
