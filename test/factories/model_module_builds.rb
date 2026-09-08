# == Schema Information
#
# Table name: model_module_builds
#
#  id              :uuid             not null, primary key
#  cargo_holds     :string
#  description     :text
#  environment     :string           not null
#  version         :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_module_id :uuid             not null
#
# Indexes
#
#  index_model_module_builds_on_environment_and_version  (environment,version)
#  index_model_module_builds_on_model_module_id          (model_module_id)
#  index_model_module_builds_on_module_and_build         (model_module_id,environment,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (model_module_id => model_modules.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :model_module_build do
    association :model_module, factory: :model_module
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    description { "What this build says the module does" }
  end
end
