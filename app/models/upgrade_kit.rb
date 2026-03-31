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
  belongs_to :model, touch: true, counter_cache: true
  belongs_to :model_upgrade

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "model_id", "model_upgrade_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["model", "model_upgrade"]
  end
end
