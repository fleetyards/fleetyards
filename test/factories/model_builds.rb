# frozen_string_literal: true

FactoryBot.define do
  factory :model_build do
    model
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    mass { 1_500.0 }
    scm_speed { 210.0 }
    max_speed { 1_200.0 }
    ground { false }
  end
end
