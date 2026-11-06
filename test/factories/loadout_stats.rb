# frozen_string_literal: true

FactoryBot.define do
  factory :loadout_stat do
    fitting factory: :model
    environment { ::ScData::Source.current.environment }
    version { ::ScData::Source.current.version }
  end
end
