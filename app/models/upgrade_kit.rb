# frozen_string_literal: true

# == Schema Information
#
# Table name: upgrade_kits
#
#  id               :uuid             not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  model_id         :uuid
#  model_upgrade_id :uuid
#
class UpgradeKit < ApplicationRecord
  belongs_to :model, optional: false, touch: true, counter_cache: true
  belongs_to :model_upgrade, optional: false
end
