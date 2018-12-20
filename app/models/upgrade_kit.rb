# frozen_string_literal: true

class UpgradeKit < ApplicationRecord
  belongs_to :model, required: true, touch: true
  belongs_to :model_upgrade, required: true
end
