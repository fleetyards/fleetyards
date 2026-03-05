# frozen_string_literal: true

# == Schema Information
#
# Table name: module_hardpoints
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_id        :uuid
#  model_module_id :uuid
#
class ModuleHardpoint < ApplicationRecord
  belongs_to :model, touch: true, counter_cache: true
  belongs_to :model_module

  def self.ransackable_attributes(auth_object = nil)
    ["model_id", "model_module_id", "created_at", "updated_at"]
  end
end
