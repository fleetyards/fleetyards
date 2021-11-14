# frozen_string_literal: true

# == Schema Information
#
# Table name: model_module_package_items
#
#  id                      :uuid             not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_module_id         :uuid
#  model_module_package_id :uuid
#
class ModelModulePackageItem < ApplicationRecord
  belongs_to :model_module_package, touch: true
  belongs_to :model_module
end
