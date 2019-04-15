# frozen_string_literal: true

class ModuleHardpoint < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :model_module
end
