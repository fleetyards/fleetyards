# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_admins
#
#  id             :uuid             not null, primary key
#  role           :string           default("admin"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  fleet_event_id :uuid             not null
#  granted_by_id  :uuid
#  user_id        :uuid             not null
#
# Indexes
#
#  index_fleet_event_admins_on_fleet_event_id              (fleet_event_id)
#  index_fleet_event_admins_on_fleet_event_id_and_user_id  (fleet_event_id,user_id) UNIQUE
#  index_fleet_event_admins_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#  fk_rails_...  (user_id => users.id)
#
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
