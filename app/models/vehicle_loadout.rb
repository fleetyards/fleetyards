# frozen_string_literal: true

class VehicleLoadout < ApplicationRecord
  # `name` is whatever the owner typed and `url` is their build, and a vehicle's
  # loadouts are destroyed with the vehicle, which goes with the account.
  include ErasableVersionsConcern

  # Written only by `Api::V1::VehicleLoadoutsController`, one save per user
  # action, so every version here is a change somebody chose to make.
  #
  # `:touch` is left out for the reason `VersionedItem::RECORDED_EVENTS`
  # documents -- `touch: true` below makes this that trap in miniature -- and
  # `:destroy` for the reason `Vehicle` leaves it out: the concern above erases
  # the row in the same transaction paper_trail writes it.
  has_paper_trail on: %i[create update]

  belongs_to :vehicle, touch: true

  # A link points at a build kept on another site; a fleetyards loadout keeps
  # its own record of what is fitted, slot by slot. Never both.
  enum :kind, {
    link: "link",
    fleetyards: "fleetyards"
  }, prefix: true

  has_many :items, -> { order(:slot_path) },
    class_name: "VehicleLoadoutItem",
    inverse_of: :vehicle_loadout,
    dependent: :delete_all

  before_validation :set_default_name, if: -> { name.blank? }

  validates :url, presence: true, if: :kind_link?
  validates :url, absence: true, if: :kind_fleetyards?
  validates :name, uniqueness: {scope: :vehicle_id}, allow_nil: true
  validate :ship_is_flight_ready, on: :create
  validate :item_list_fits, unless: -> { item_list.nil? }

  after_save :write_item_list, unless: -> { item_list.nil? }

  attr_reader :item_list

  # The whole fitting at once: a list of `{slot_path:, item_type:, item_id:}`
  # that replaces whatever was fitted before, written after the loadout
  # validates.
  def item_list=(list)
    @item_list = Array(list).map do |item|
      item = item.to_h.symbolize_keys
      {slot_path: item[:slot_path].to_s, item_type: item[:item_type].to_s, item_id: item[:item_id].to_s}
    end
  end

  scope :active, -> { where(active: true) }

  # Iterated rather than `update_all` so the loadout that stops being active
  # files a version too: a history saying only what was switched on would not
  # say what it replaced. Scoped to the active ones, which the switch itself
  # keeps to at most one, so this is one write rather than one per sibling.
  def activate!
    transaction do
      vehicle.vehicle_loadouts.active.where.not(id: id).find_each do |loadout|
        loadout.update!(active: false)
      end

      update!(active: true)
    end
  end

  def url_source
    return if url.blank?

    host = begin
      URI.parse(url).host&.downcase&.delete_prefix("www.")
    rescue
      nil
    end
    return if host.blank?

    if host.include?("erkul.games")
      "erkul"
    elsif host.include?("spviewer.eu")
      "spviewer"
    end
  end

  private def ship_is_flight_ready
    return if vehicle&.model&.production_status == "flight-ready"

    errors.add(:base, :not_flight_ready)
  end

  private def item_list_fits
    return if item_list.empty?
    return errors.add(:items, :not_fleetyards) unless kind_fleetyards?

    paths = item_list.pluck(:slot_path)
    errors.add(:items, :slot_taken) if paths.uniq.size != paths.size

    unless item_list.all? { |item| VehicleLoadoutItem::ITEM_TYPES.include?(item[:item_type]) }
      return errors.add(:items, :item_type_not_supported)
    end

    # A hardpoint inside a module or a turret only exists while that is fitted.
    nested = paths.select { |path| path.include?("/") }
    if nested.any? { |path| paths.exclude?(path.rpartition("/").first) }
      errors.add(:items, :parent_not_fitted)
    end

    modules_fit
  end

  # A module goes in a slot on the hull itself, named by the module hardpoint,
  # so one whose slot the game files never revealed matches none and cannot be
  # fitted. Whether the ship owns it does not matter: a loadout is a plan.
  private def modules_fit
    modules = item_list.select { |item| item[:item_type] == "ModelModule" }
    return if modules.empty?

    module_ids = modules.pluck(:item_id)
    fitting = ModuleHardpoint.where(model_id: vehicle.model_id, model_module_id: module_ids)
      .pluck(:model_module_id, :slot)
    unless modules.all? { |item| fitting.include?([item[:item_id], item[:slot_path]]) }
      errors.add(:items, :module_not_in_slot)
    end
  end

  private def write_item_list
    items.delete_all
    item_list.each { |item| items.create!(item) }
    @item_list = nil
  end

  private def set_default_name
    base = case url_source
    when "erkul" then "Erkul Loadout"
    when "spviewer" then "SPViewer Loadout"
    else kind_fleetyards? ? "Fleetyards Loadout" : "Custom Loadout"
    end

    existing = vehicle.vehicle_loadouts.where("name LIKE ?", "#{base}%").pluck(:name)

    self.name = if existing.exclude?(base)
      base
    else
      counter = 2
      counter += 1 while existing.include?("#{base} #{counter}")
      "#{base} #{counter}"
    end
  end
end
