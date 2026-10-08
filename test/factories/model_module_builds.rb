FactoryBot.define do
  factory :model_module_build do
    association :model_module, factory: :model_module
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    description { "What this build says the module does" }
  end
end
