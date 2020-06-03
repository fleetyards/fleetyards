# frozen_string_literal: true

class UpgradeKit < ApplicationRecord
  belongs_to :model, optional: false, touch: true, counter_cache: true
  belongs_to :model_upgrade, optional: false
end
