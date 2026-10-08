# frozen_string_literal: true

class ModelModulePackageItem < ApplicationRecord
  belongs_to :model_module_package, touch: true
  belongs_to :model_module
end
