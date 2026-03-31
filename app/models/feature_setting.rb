# frozen_string_literal: true

# == Schema Information
#
# Table name: feature_settings
#
#  id           :uuid             not null, primary key
#  feature_name :string           not null
#  self_service :boolean          default(FALSE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_feature_settings_on_feature_name  (feature_name) UNIQUE
#
class FeatureSetting < ApplicationRecord
  validates :feature_name, presence: true, uniqueness: true

  def self.self_service?(feature_name)
    exists?(feature_name: feature_name.to_s, self_service: true)
  end

  def self.self_service_feature_names
    where(self_service: true).pluck(:feature_name)
  end
end
