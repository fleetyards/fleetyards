# frozen_string_literal: true

# == Schema Information
#
# Table name: feature_settings
#
#  id                 :uuid             not null, primary key
#  feature_name       :string           not null
#  self_service_fleet :boolean          default(FALSE), not null
#  self_service_user  :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_feature_settings_on_feature_name  (feature_name) UNIQUE
#
class FeatureSetting < ApplicationRecord
  # One flag of these per surface a self-service toggle can live on, rather than
  # a boolean and an exclusive scope. The two are independent: a fleet feature
  # keeps a per-member preview in personal settings, so it wants both — and the
  # old pair could not express a fleet toggle without one.
  #
  # Both are written only by /admin/features. The registry declares neither, and
  # a deploy never touches them.
  #
  # The API still names a single surface per row, so the names live here too.
  USER_SCOPE = "user"
  FLEET_SCOPE = "fleet"
  SELF_SERVICE_SCOPES = [USER_SCOPE, FLEET_SCOPE].freeze

  validates :feature_name, presence: true, uniqueness: true

  scope :user_toggleable, -> { where(self_service_user: true) }
  scope :fleet_toggleable, -> { where(self_service_fleet: true) }

  # The flags a user may switch for themselves in Settings → Features. Includes
  # the fleet features they can preview without switching one on for the fleet.
  def self.user_toggleable_feature_names
    user_toggleable.pluck(:feature_name)
  end

  # The flags a fleet's admins may switch for the whole fleet.
  def self.fleet_toggleable_feature_names
    fleet_toggleable.pluck(:feature_name)
  end

  def self.user_toggleable?(feature_name)
    exists?(feature_name: feature_name.to_s, self_service_user: true)
  end

  def self.fleet_toggleable?(feature_name)
    exists?(feature_name: feature_name.to_s, self_service_fleet: true)
  end

  # Whether a toggle exists on any surface, for /admin/features listing what it
  # has handed out.
  def self.toggleable_anywhere?(feature_name)
    where(feature_name: feature_name.to_s)
      .where(self_service_user: true).or(where(feature_name: feature_name.to_s, self_service_fleet: true))
      .exists?
  end
end
