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

    trait :hangar_import do
      type { Imports::HangarImport }
      user
    end

    trait :hangar_sync do
      type { Imports::HangarSync }
      user
    end

    trait :model_import do
      type { Imports::ModelImport }
    end

    trait :models_import do
      type { Imports::ModelsImport }
    end

    trait :modules_import do
      type { Imports::ModulesImport }
    end

    trait :paints_import do
      type { Imports::PaintsImport }
    end

    trait :loaners_import do
      type { Imports::LoanersImport }
    end
  end
end
