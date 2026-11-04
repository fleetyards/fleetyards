# frozen_string_literal: true

# A free fleetchart arrangement a user saved, to reopen or to share by link.
class FleetchartLayout < ApplicationRecord
  MAX_PER_USER = 50
  MAX_PLACEMENTS = 5000
  MAX_HEADING_LENGTH = 100
  MAX_CATALOGUE_ID_LENGTH = 64

  VIEWPOINTS = %w[top port angled front starboard bottom angledRear rear].freeze
  FACINGS = %w[left top right bottom].freeze
  STATES = %w[flight extended landed].freeze

  belongs_to :user

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validate :layout_limit, on: :create
  validate :placements_shape

  before_validation :keep_placements_of_owned_vehicles
  # Only when they change: a model hidden for now must not vanish from a layout
  # because it was renamed or shared meanwhile.
  before_validation :keep_catalogue_placements_of_listed_models, if: :catalogue_placements_changed?

  def shared?
    share_token.present?
  end

  def share!
    update!(share_token: SecureRandom.urlsafe_base64(18)) unless shared?
  end

  def unshare!
    update!(share_token: nil)
  end

  # Sharing a layout is the owner showing it to someone, so everything placed in it
  # comes along, whatever the hangar's own privacy settings say about those ships.
  def shared_vehicles
    user.vehicles.where(id: placements.reject { |placement| placement["removed"] }.pluck("vehicle_id"))
  end

  # Ships the owner tried out without having them, each placement drawing its own copy.
  def shared_models
    Model.visible.active.where(id: catalogue_placements.pluck("model_id"))
  end

  private def keep_placements_of_owned_vehicles
    return unless placements.is_a?(Array) && user

    owned = user.vehicles.where(id: placements.filter_map { |placement| vehicle_id_of(placement) }).pluck(:id)

    self.placements = placements.select { |placement| owned.include?(vehicle_id_of(placement)) }
  end

  private def keep_catalogue_placements_of_listed_models
    return unless catalogue_placements.is_a?(Array)

    model_ids = catalogue_placements.filter_map { |placement| model_id_of(placement) }
    listed = Model.visible.active.where(id: model_ids).pluck(:id).to_set

    self.catalogue_placements = catalogue_placements.select { |placement| listed.include?(model_id_of(placement)) }
  end

  private def vehicle_id_of(placement)
    placement["vehicle_id"] if placement.is_a?(Hash)
  end

  private def model_id_of(placement)
    placement["model_id"] if placement.is_a?(Hash)
  end

  private def layout_limit
    return unless user && user.fleetchart_layouts.count >= MAX_PER_USER

    errors.add(:base, :layout_limit_reached, count: MAX_PER_USER)
  end

  private def placements_shape
    unless placements.is_a?(Array) && catalogue_placements.is_a?(Array) &&
        placements.size + catalogue_placements.size <= MAX_PLACEMENTS
      errors.add(:placements, :invalid)
      return
    end

    errors.add(:placements, :invalid) unless placements.all? { |placement| valid_placement?(placement) }
    errors.add(:catalogue_placements, :invalid) unless valid_catalogue_placements?
  end

  private def valid_catalogue_placements?
    ids = catalogue_placements.pluck("id")

    ids.uniq.size == ids.size &&
      ids.all? { |id| id.is_a?(String) && id.present? && id.length <= MAX_CATALOGUE_ID_LENGTH } &&
      catalogue_placements.all? { |placement| valid_placement?(placement) }
  end

  private def valid_placement?(placement)
    placement["x"].is_a?(Numeric) && placement["y"].is_a?(Numeric) &&
      allowed?(placement["facing"], FACINGS) &&
      allowed?(placement["viewpoint"], VIEWPOINTS) &&
      allowed?(placement["state"], STATES) &&
      (placement["order"].nil? || placement["order"].is_a?(Numeric)) &&
      [nil, true, false].include?(placement["removed"]) &&
      (placement["heading"].nil? || (placement["heading"].is_a?(String) && placement["heading"].length <= MAX_HEADING_LENGTH))
  end

  private def allowed?(value, values)
    value.nil? || values.include?(value)
  end
end
