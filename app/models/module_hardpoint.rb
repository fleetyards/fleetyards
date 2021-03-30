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
end
