# frozen_string_literal: true

class FleetEventAdmin < ApplicationRecord
  ROLES = %w[admin moderator].freeze

  belongs_to :fleet_event, touch: true
  belongs_to :user
  belongs_to :granted_by, class_name: "User", optional: true

  validates :role, inclusion: {in: ROLES}
  validates :user_id, uniqueness: {scope: :fleet_event_id}

  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator"
  end
end
