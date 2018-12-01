# frozen_string_literal: true

class ModuleHardpoint < ApplicationRecord
  belongs_to :model, required: true, touch: true
  belongs_to :model_module, required: true
end
