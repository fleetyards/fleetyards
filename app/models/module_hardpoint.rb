# frozen_string_literal: true

class ModuleHardpoint < ApplicationRecord
  belongs_to :model, touch: true, counter_cache: true
  belongs_to :model_module
end
