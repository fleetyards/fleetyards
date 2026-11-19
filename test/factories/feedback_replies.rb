# frozen_string_literal: true

FactoryBot.define do
  factory :feedback_reply do
    feedback
    body { "Could you tell me more?" }
  end
end
