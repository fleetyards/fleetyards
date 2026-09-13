# == Schema Information
#
# Table name: imports
#
#  id                        :uuid             not null, primary key
#  aasm_state                :string
#  add_bundled_vehicles      :boolean          default(TRUE), not null
#  cancel_requested_at       :datetime
#  cancelled_at              :datetime
#  failed_at                 :datetime
#  finished_at               :datetime
#  import_data               :text
#  info                      :text
#  input                     :jsonb
#  output                    :jsonb
#  started_at                :datetime
#  type                      :string
#  unmatched_vehicles_action :string           default("wishlist"), not null
#  version                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  admin_user_id             :uuid
#  hangar_group_id           :uuid
#  unmatched_hangar_group_id :uuid
#  user_id                   :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type        (aasm_state,type)
#  index_imports_on_admin_user_id              (admin_user_id)
#  index_imports_on_hangar_group_id            (hangar_group_id)
#  index_imports_on_type                       (type)
#  index_imports_on_type_and_id                (type,id)
#  index_imports_on_unmatched_hangar_group_id  (unmatched_hangar_group_id)
#  index_imports_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (hangar_group_id => hangar_groups.id) ON DELETE => nullify
#  fk_rails_...  (unmatched_hangar_group_id => hangar_groups.id) ON DELETE => nullify
#
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
  end
end
