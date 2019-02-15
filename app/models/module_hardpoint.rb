# frozen_string_literal: true

class ModuleHardpoint < ApplicationRecord
  belongs_to :model, optional: false, touch: true
  belongs_to :model_module, optional: false
end
