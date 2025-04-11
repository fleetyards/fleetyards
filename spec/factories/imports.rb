FactoryBot.define do
  factory :import do
    type do
      [
        Imports::ScData::AllImport, Imports::ScData::ModelImport, Imports::ScData::ModelsImport,
        Imports::HangarImport, Imports::HangarSync, Imports::ModelImport, Imports::ModelsImport
      ].sample
    end

    trait :scdata_all do
      type { Imports::ScData::AllImport }
    end
  end
end
