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

  has_many :loadout_stats, as: :fitting, dependent: :delete_all

  before_validation :set_default_name, if: -> { name.blank? }

  validates :url, presence: true, if: :kind_link?
  validates :url, absence: true, if: :kind_fleetyards?
  validates :name, uniqueness: {scope: :vehicle_id}, allow_nil: true
  validate :ship_is_flight_ready, on: :create
  validate :item_list_fits, unless: -> { item_list.nil? }
  validate :crafted_items_fit, unless: -> { item_list.nil? }
  validate :power_presets_fit

  after_save :write_item_list, unless: -> { item_list.nil? }
  after_commit :refresh_stats, on: %i[create update], if: :kind_fleetyards?

  attr_reader :item_list

  # The whole fitting at once: a list of `{slot_path:, item_type:, item_id:}`
  # that replaces whatever was fitted before, written after the loadout
  # validates. A crafted component adds `crafted: {blueprint_id:, qualities:
  # [{position:, quality:}]}`, which is stored as the recipe and a quality per
  # recipe slot.
  def item_list=(list)
    @crafted_slot_repeated = false
    @saved_craftings = nil
    @item_list = Array(list).map do |item|
      item = item.to_h.symbolize_keys
      item_type = item[:item_type].to_s
      item_id = (item_type == VehicleLoadoutItem::EMPTY) ? nil : item[:item_id].to_s.downcase
      {slot_path: item[:slot_path].to_s, item_type:, item_id:, **crafting_of(item[:crafted])}
    end
    @loadout_slots = nil
  end

  POWER_MODES = %w[scm nav].freeze
  MAX_POWER_PRESETS = 5
  MAX_POWER_PRESET_NAME = 40
  # More than any power port takes: the largest systems run to a dozen pips.
  MAX_POWER_PRESET_PIPS = 100

  # Named power splits the owner keeps with the loadout, one per flight mode:
  # the pips set by hand, `{port_path:, pips:}` per power port. Ports left out
  # follow the game's automatic balance.
  def power_presets=(list)
    super(Array(list).map do |preset|
      preset = preset.to_h.symbolize_keys
      splits = POWER_MODES.index_with do |mode|
        Array(preset[mode.to_sym]).map do |override|
          override = override.to_h.symbolize_keys
          {"port_path" => override[:port_path].to_s, "pips" => override[:pips]}
        end
      end
      {"name" => preset[:name].to_s.strip, **splits}
    end)
  end

  scope :active, -> { where(active: true) }

  # What a visitor of a public hangar may see: the loadout's page, and the
  # active one on the ship's plaque.
  scope :public_loadouts, -> { where(public: true) }

  # A ship's first loadout becomes its default, and on a ship its owner shows
  # publicly that one is shown too, as the plaque showed the active loadout
  # before loadouts had a visibility. Any other starts private.
  def public_by_default?
    vehicle.public? && vehicle.vehicle_loadouts.active.where.not(id:).none?
  end

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

  # The saved fitting's slots, the stock parts it left in place included.
  def slots
    LoadoutSlots.new(vehicle.model, items.map { |item| item.slice(:slot_path, :item_type, :item_id).symbolize_keys })
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

  # Why the build in force refuses an item, one per item.
  ITEM_PROBLEMS = %w[
    parent_not_fitted module_not_in_slot slot_unknown component_not_in_slot slot_not_editable nothing_to_empty
  ].freeze

  # The saved items the build in force refuses, each with the reason a save
  # would give: a loadout floats with the build, so one that fitted when it was
  # saved can stop fitting when a new build changes a slot.
  #
  # Taking a refused item out can strand what sat inside it -- a module's own
  # slots, guns in ports the stock turret does not have -- so the check repeats
  # on what a save would keep, as the editor's save does.
  def item_problems
    list = items.map { |item| item.slice(:slot_path, :item_type, :item_id).symbolize_keys }
    problems = []
    loop do
      refused = refused_items(list, LoadoutSlots.new(vehicle.model, list))
      break if refused.empty?

      problems.concat(refused)
      paths = refused.pluck(:slot_path).to_set
      list = list.reject { |item| paths.include?(item[:slot_path]) }
    end
    problems.sort_by { |problem| problem[:slot_path] }.map { |problem| problem.except(:codes) }
  end

  private def item_list_fits
    return if item_list.empty?
    return errors.add(:items, :not_fleetyards) unless kind_fleetyards?

    paths = item_list.pluck(:slot_path)
    errors.add(:items, :slot_taken) if paths.uniq.size != paths.size

    unless item_list.all? { |item| VehicleLoadoutItem::ITEM_TYPES.include?(item[:item_type]) }
      return errors.add(:items, :item_type_not_supported)
    end

    refused_items(item_list, loadout_slots).flat_map { |item| item[:codes] }.uniq.each { |code| errors.add(:items, code) }
  end

  # Every item that does not fit, as `{slot_path:, item_type:, item_id:, code:,
  # codes:}`: every check it fails, and the first of them to show the owner.
  private def refused_items(list, slots)
    reasons = Hash.new { |hash, item| hash[item] = [] }
    refuse = ->(item, code) { reasons[item] << code }

    # A hardpoint inside a module or a turret only exists while something sits
    # in it: fitted there, or, for a component slot, the stock part left in.
    list.each do |item|
      path = item[:slot_path]
      refuse.call(item, :parent_not_fitted) if path.include?("/") && !slots.occupied?(path.rpartition("/").first)
    end

    modules_fit(list, &refuse)
    components_fit(list, slots, &refuse)
    empties_fit(list, slots, &refuse)

    list.filter_map { |item| item.merge(code: reasons[item].first, codes: reasons[item]) if reasons.key?(item) }
  end

  # A slot can be emptied where a part can be fitted and there is one to take
  # out: a component slot a player fits, holding a stock part, which the game
  # does not lock. A module slot is empty by leaving it out.
  private def empties_fit(list, slots)
    list.select { |item| item[:item_type] == VehicleLoadoutItem::EMPTY }.each do |item|
      slot = slots[item[:slot_path]]
      if slot.nil? || slot.module_slot? || !slots.fittable?(item[:slot_path])
        next yield(item, :slot_unknown)
      end
      next yield(item, :nothing_to_empty) if slot.stock.nil?

      yield(item, :slot_not_editable) unless slot.editable?
    end
  end

  # A component goes in any slot below a hull slot a player fits, whose port
  # takes its type and size in the build we are on. Whether anybody owns it does
  # not matter, as for modules, but it has to be a part the catalogue offers in
  # this build -- or the one the slot came with. A slot the game locks takes
  # only that.
  private def components_fit(list, slots)
    list.select { |item| item[:item_type] == "Component" }.each do |item|
      slot = slots[item[:slot_path]]
      next yield(item, :slot_unknown) if slot.nil? || !slots.fittable?(item[:slot_path])

      component = slots.fitted(item[:slot_path])
      offered = component.present? && (component.id == slot.stock&.id || (!component.retired? && component.catalogued?))
      next yield(item, :component_not_in_slot) unless offered && slots.fits?(slot, component)

      yield(item, :slot_not_editable) if !slot.editable? && component.id != slot.stock&.id
    end
  end

  private def crafting_of(crafted)
    crafted = crafted.to_h.symbolize_keys
    return {blueprint_id: nil, crafted_qualities: {}} if crafted[:blueprint_id].blank?

    pairs = Array(crafted[:qualities]).map do |entry|
      entry = entry.to_h.symbolize_keys
      [entry[:position].to_s, entry[:quality]]
    end
    qualities = pairs.to_h
    @crafted_slot_repeated ||= qualities.size != pairs.size

    {blueprint_id: crafted[:blueprint_id].to_s.downcase, crafted_qualities: qualities}
  end

  # A crafted part is a component made from a recipe for it, in the build in
  # force, with a quality on the game's 0-1000 scale for slots the recipe has. A
  # slot left out was filled at the neutral grade.
  #
  # A crafting saved before and sent back unchanged is kept as it is: a new
  # build can drop or reshape the recipe, and refusing it then would refuse
  # every later save of the loadout, whatever else it changed.
  private def crafted_items_fit
    return errors.add(:items, :crafted_slot_repeated) if @crafted_slot_repeated

    crafted = item_list.select { |item| item[:blueprint_id].present? }.reject { |item| saved_crafting?(item) }
    return if crafted.empty?

    return errors.add(:items, :crafted_not_component) if crafted.any? { |item| item[:item_type] != "Component" }

    builds = Blueprint.readable_builds(Blueprint.served_source)
      .where(blueprint_id: crafted.pluck(:blueprint_id), craftable_type: "Component")
      .includes(:cost_slots)
      .index_by { |build| [build.blueprint_id, build.craftable_id] }
    crafted.each do |item|
      build = builds[[item[:blueprint_id], item[:item_id]]]
      next errors.add(:items, :crafted_not_craftable) if build.nil?

      positions = build.cost_slots.map { |slot| slot.position.to_s }
      qualities = item[:crafted_qualities]
      errors.add(:items, :crafted_slot_unknown) unless (qualities.keys - positions).empty?
      errors.add(:items, :crafted_quality_out_of_range) unless qualities.values.all? { |quality| valid_quality?(quality) }
    end
  end

  private def power_presets_fit
    presets = Array(power_presets)
    return if presets.empty?
    # A linked loadout fits nothing here, so there is no split to keep.
    return errors.add(:power_presets, :not_fleetyards) unless kind_fleetyards?

    errors.add(:power_presets, :too_many, count: MAX_POWER_PRESETS) if presets.size > MAX_POWER_PRESETS

    names = presets.map { |preset| preset["name"].to_s.downcase }
    errors.add(:power_presets, :name_blank) if names.any?(&:blank?)
    errors.add(:power_presets, :name_taken) if names.uniq.size != names.size
    errors.add(:power_presets, :name_too_long, count: MAX_POWER_PRESET_NAME) if names.any? { |name| name.length > MAX_POWER_PRESET_NAME }

    splits = presets.flat_map { |preset| POWER_MODES.map { |mode| Array(preset[mode]) } }
    errors.add(:power_presets, :port_repeated) if splits.any? { |split| split.pluck("port_path").uniq.size != split.size }

    valid = splits.flatten.all? do |override|
      override["port_path"].present? && override["pips"].is_a?(Integer) && override["pips"].between?(0, MAX_POWER_PRESET_PIPS)
    end
    errors.add(:power_presets, :pips_invalid) unless valid
  end

  private def saved_crafting?(item)
    @saved_craftings ||= persisted? ? items.reload.select(&:crafted?).index_by(&:slot_path) : {}
    saved = @saved_craftings[item[:slot_path]]

    saved.present? && saved.item_id == item[:item_id] && saved.blueprint_id == item[:blueprint_id] &&
      saved.crafted_qualities == item[:crafted_qualities]
  end

  private def valid_quality?(quality)
    quality.is_a?(Integer) && quality.between?(0, 1000)
  end

  private def loadout_slots
    @loadout_slots ||= LoadoutSlots.new(vehicle.model, item_list)
  end

  # A module goes in a slot on the hull itself, named by the module hardpoint,
  # so one whose slot the game files never revealed matches none and cannot be
  # fitted. Whether the ship owns it does not matter: a loadout is a plan.
  private def modules_fit(list)
    modules = list.select { |item| item[:item_type] == "ModelModule" }
    return if modules.empty?

    fitting = ModuleHardpoint.where(model_id: vehicle.model_id, model_module_id: modules.pluck(:item_id))
      .pluck(:model_module_id, :slot)
    modules.each do |item|
      yield(item, :module_not_in_slot) unless fitting.include?([item[:item_id], item[:slot_path]])
    end
  end

  # One insert rather than a create per item, each touching the loadout and the
  # vehicle. The explicit touch is what busts the caches keyed on both when only
  # the fitting changed, including when it was emptied.
  private def write_item_list
    items.delete_all
    items.insert_all!(item_list) if item_list.any?
    @item_list = nil
    @loadout_slots = nil
    @saved_craftings = nil
    touch
  end

  private def refresh_stats
    LoadoutStatsJob.perform_async(id)
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
