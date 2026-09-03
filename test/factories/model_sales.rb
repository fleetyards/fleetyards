# frozen_string_literal: true

FactoryBot.define do
  factory :model_sale do
    model
    started_at { 1.week.ago }

    trait :finished do
      ended_at { 5.days.ago }
    end
  end
end
