# frozen_string_literal: true

# One answer to "what is this berth built for": so many of a class, at once.
#
# The entries on a dock are alternatives rather than a sum. A deck that takes
# one large ship or two mediums carries both entries, and a reader picks the row
# that matches what they are carrying.
# == Schema Information
#
# Table name: dock_capacities
#
#  id         :uuid             not null, primary key
#  display    :boolean          default(FALSE), not null
#  ladder     :integer          not null
#  quantity   :integer          default(1), not null
#  size       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dock_id    :uuid             not null
#
# Indexes
#
#  index_dock_capacities_on_dock_id                      (dock_id)
#  index_dock_capacities_on_dock_id_and_ladder_and_size  (dock_id,ladder,size) UNIQUE
#  index_dock_capacities_on_one_display_per_dock         (dock_id) UNIQUE WHERE display
#
# Foreign Keys
#
#  fk_rails_...  (dock_id => docks.id)
#
class DockCapacity < ApplicationRecord
  belongs_to :dock, touch: true

  # Which ladder `size` is measured on. Ship classes come from the game's
  # `landingpadsize` table; vehicle classes are curated, and the two do not line
  # up -- the game describes three ground-vehicle boxes against our seven rungs.
  enum :ladder, {ship: 0, vehicle: 1}, prefix: true

  LADDER_CLASSES = {
    "ship" => Dock.ship_sizes.keys.freeze,
    "vehicle" => ::Model::VEHICLE_SIZES
  }.freeze

  validates :size, presence: true, uniqueness: {scope: %i[dock_id ladder]}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}
  validate :size_belongs_to_its_ladder
  validate :one_display_per_dock

  scope :for_display, -> { where(display: true) }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at display dock_id id id_value ladder quantity size updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[dock]
  end

  # The class as a reader sees it. The two ladders answer differently: ship
  # classes are a `Dock` enum with translated labels ("Small (S)"), while the
  # vehicle ladder is a plain list and `Model.vehicle_size_filters` humanizes it,
  # so this matches what the filter already shows.
  def size_label
    return ::Dock.human_enum_name(:ship_size, size) if ladder_ship?

    size.humanize
  end

  private def size_belongs_to_its_ladder
    return if ladder.blank? || size.blank?
    return if LADDER_CLASSES.fetch(ladder, []).include?(size)

    errors.add(:size, :not_on_ladder)
  end

  # The unique index says the same thing, but a validation says it in the
  # admin's language rather than as a 500.
  private def one_display_per_dock
    return unless display?

    conflict = DockCapacity.where(dock_id:, display: true).where.not(id:).exists?

    errors.add(:display, :already_set) if conflict
  end
end
