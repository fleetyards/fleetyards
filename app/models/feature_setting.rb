# frozen_string_literal: true

# == Schema Information
#
# Table name: feature_settings
#
#  id                 :uuid             not null, primary key
#  feature_name       :string           not null
#  self_service       :boolean          default(FALSE), not null
#  self_service_scope :string           default("user"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_feature_settings_on_feature_name  (feature_name) UNIQUE
#
class FeatureSetting < ApplicationRecord
  # Which surface a flag's self-service toggle lives on. Owned here rather than
  # in the registry: whether a flag is self-service at all, and where, is decided
  # at /admin/features, and a deploy has no say in either.
  USER_SCOPE = "user"
  FLEET_SCOPE = "fleet"
  SELF_SERVICE_SCOPES = [USER_SCOPE, FLEET_SCOPE].freeze

  validates :feature_name, presence: true, uniqueness: true
  validates :self_service_scope, inclusion: {in: SELF_SERVICE_SCOPES}

  scope :self_service, -> { where(self_service: true) }

  # Scope is a required argument rather than an optional filter: a caller that
  # serves one surface has to say which, or a fleet's tab would offer flags that
  # belong in personal settings.
  def self.self_service?(feature_name, scope:)
    exists?(feature_name: feature_name.to_s, self_service: true, self_service_scope: scope.to_s)
  end

  def self.self_service_feature_names(scope:)
    where(self_service: true, self_service_scope: scope.to_s).pluck(:feature_name)
  end

  # Scope-agnostic, for the two callers that genuinely have no surface in mind:
  # /admin/features showing whether a toggle exists at all, and the personal
  # toggle, which may switch any self-service flag on for its own user.
  def self.self_service_anywhere?(feature_name)
    exists?(feature_name: feature_name.to_s, self_service: true)
  end

  # Every self-service flag with the surface that owns its fleet-wide switch.
  def self.self_service_scopes
    self_service.pluck(:feature_name, :self_service_scope)
  end
end
