# frozen_string_literal: true

# A free fleetchart arrangement a user saved, to reopen or to share by link.
class FleetchartLayout < ApplicationRecord
  MAX_PER_USER = 50
  MAX_PLACEMENTS = 5000

  VIEWPOINTS = %w[top port angled front starboard bottom angledRear rear].freeze
  FACINGS = %w[left top right bottom].freeze
  STATES = %w[flight extended landed].freeze

  belongs_to :user

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validate :layout_limit, on: :create
  validate :placements_shape

  before_validation :keep_placements_of_owned_vehicles

  def shared?
    share_token.present?
  end

  def share!
    update!(share_token: SecureRandom.urlsafe_base64(18)) unless shared?
  end

  def unshare!
    update!(share_token: nil)
  end

  # Sharing a layout hands over its arrangement, not the ships a public hangar would
  # not show: private ones and the wishlist stay out, even for someone with the link.
  def shared_vehicles
    user.vehicles.visible.purchased.public.where(id: placements.pluck("vehicle_id"))
  end

  private def keep_placements_of_owned_vehicles
    return unless placements.is_a?(Array) && user

    owned = user.vehicles.where(id: placements.filter_map { |placement| vehicle_id_of(placement) }).pluck(:id)

    self.placements = placements.select { |placement| owned.include?(vehicle_id_of(placement)) }
  end

  private def vehicle_id_of(placement)
    placement["vehicle_id"] if placement.is_a?(Hash)
  end

  private def layout_limit
    return unless user && user.fleetchart_layouts.count >= MAX_PER_USER

    errors.add(:base, :layout_limit_reached, count: MAX_PER_USER)
  end

  private def placements_shape
    unless placements.is_a?(Array) && placements.size <= MAX_PLACEMENTS
      errors.add(:placements, :invalid)
      return
    end

    errors.add(:placements, :invalid) unless placements.all? { |placement| valid_placement?(placement) }
  end

  private def valid_placement?(placement)
    placement["x"].is_a?(Numeric) && placement["y"].is_a?(Numeric) &&
      allowed?(placement["facing"], FACINGS) &&
      allowed?(placement["viewpoint"], VIEWPOINTS) &&
      allowed?(placement["state"], STATES) &&
      (placement["order"].nil? || placement["order"].is_a?(Numeric))
  end

  private def allowed?(value, values)
    value.nil? || values.include?(value)
  end
end
