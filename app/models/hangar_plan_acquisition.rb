# frozen_string_literal: true

# How one ship of a slot is obtained: kept from the hangar, bought on the
# store or in game, or bought back (a pledge already in the buy-back list, or
# the pledge of a ship the plan melts), then optionally upgraded step by step until
# it is the planned ship. The start and every step are resources the user owns
# at most once, so nothing here may be spent twice within a plan. A start with
# no upgrades that is not the planned ship holds both ends while its route has
# yet to be planned. A slot with no ship yet holds its starts itself, and hands
# them to the first ship it gets. A pledge bought back returns all of its ships,
# so each of the others can be a bundled start, free, that goes with it.
class HangarPlanAcquisition < ApplicationRecord
  START_KINDS = %w[owned store ingame buyback melted bundled].freeze
  # Bought back, so paid like one: with store credit and a token, or new money.
  BUYBACK_START_KINDS = %w[buyback melted].freeze
  # Named by a ship of the live hangar: kept as it is, or melted and bought back.
  VEHICLE_KINDS = %w[owned melted].freeze
  BUYBACK_SHIP_KINDS = %w[ship package other].freeze
  # Bought or earned as the planned ship, so with none planned there is no ship
  # to name yet.
  SHIPLESS_KINDS = %w[store ingame].freeze

  belongs_to :hangar_plan, touch: true
  belongs_to :candidate, class_name: "HangarPlanCandidate", foreign_key: :hangar_plan_candidate_id,
    inverse_of: :acquisitions, optional: true
  belongs_to :slot, class_name: "HangarPlanSlot", foreign_key: :hangar_plan_slot_id,
    inverse_of: :starts, optional: true
  belongs_to :start_model, class_name: "Model", optional: true
  belongs_to :source_vehicle, class_name: "Vehicle", optional: true
  belongs_to :buyback_pledge, optional: true
  belongs_to :bundled_with, class_name: "HangarPlanAcquisition", optional: true, inverse_of: :bundled_starts

  has_many :bundled_starts, class_name: "HangarPlanAcquisition", foreign_key: :bundled_with_id,
    inverse_of: :bundled_with, dependent: :destroy

  has_many :upgrade_steps, -> { order(:position) },
    class_name: "HangarPlanUpgradeStep", inverse_of: :acquisition, dependent: :destroy

  validates :start_kind, inclusion: {in: START_KINDS}
  validates :price_override, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :held_by_a_ship_or_an_empty_slot
  validate :start_model_known
  validate :start_source, if: :start_changed?
  validate :quantity_available, if: -> {
    new_record? || will_save_change_to_hangar_plan_candidate_id? || will_save_change_to_hangar_plan_slot_id?
  }
  validate :chain_ends_on_candidate
  validate :chain_resources_available

  before_validation :assign_start_model
  # Only a buy-back can spend a buy-back token, and one spends it unless the
  # user says otherwise, so a start changed to a buy-back starts out marked too.
  before_validation -> {
    if BUYBACK_START_KINDS.exclude?(start_kind)
      self.uses_buyback_token = false
    elsif start_kind_changed? && !uses_buyback_token_came_from_user?
      self.uses_buyback_token = true
    end
  }
  before_create -> { self.price_snapshot ||= list_price }
  # A route that starts somewhere else was planned anew, so its price as planned
  # is what the new start costs today.
  before_update -> { self.price_snapshot = list_price }, if: :start_changed?
  # Another pledge, or another of its ships to start as, brings other ships along.
  # A melted start's ship follows its source vehicle, and is looked up again on
  # every save, so only a buy-back's ship counts as picked.
  after_update -> { bundled_starts.destroy_all }, if: -> {
    saved_change_to_start_kind? || saved_change_to_buyback_pledge_id? || saved_change_to_source_vehicle_id? ||
      (start_kind == "buyback" && saved_change_to_start_model_id?)
  }

  def final_model
    ordered_steps.last&.target_model || start_model
  end

  def route_complete?
    candidate.present? && final_model&.id == candidate.model_id
  end

  # Loaded rather than queried, so steps built for an unsaved chain count too.
  def ordered_steps
    upgrade_steps.to_a.reject(&:marked_for_destruction?).sort_by(&:position)
  end

  # What starting this way costs today, before an override: an owned ship cost
  # nothing more, an in-game purchase costs no USD.
  def list_price
    case start_kind
    when "owned", "ingame", "bundled" then 0
    when "store" then start_model&.pledge_price
    when "buyback" then buyback_pledge&.price
    when "melted" then melted_price
    end
  end

  def price
    price_override || list_price
  end

  def snapshot_price
    price_override || price_snapshot
  end

  def source_missing?
    case start_kind
    when "owned" then live_source_vehicle.nil?
    when "buyback" then buyback_pledge.nil? || buyback_pledge.user_id != hangar_plan.user_id
    when "melted" then source_melt.nil?
    when "bundled"
      bundled_with.nil? || bundled_with.source_missing? ||
        HangarPlans::BundledShips.for(bundled_with).none? { |model| model.id == start_model_id }
    else false
    end
  end

  # The plan's melt a melted start buys the pledge back from: the ship's own,
  # or that of another ship of its pledge, since melting one melts them all.
  def source_melt
    return if source_vehicle.blank?

    melts = hangar_plan.melts.includes(:vehicle).to_a
    melts.find { |melt| melt.vehicle_id == source_vehicle_id } ||
      melts.find { |melt| source_vehicle.rsi_pledge_id.present? && melt.vehicle&.rsi_pledge_id == source_vehicle.rsi_pledge_id }
  end

  def source_changed?
    start_kind == "owned" && live_source_vehicle.present? && live_source_vehicle.model_id != start_model_id
  end

  def live_source_vehicle
    return if source_vehicle.blank?

    source_vehicle if hangar_plan.pledged_vehicle_ids.include?(source_vehicle.id)
  end

  # The ship a start from the live hangar begins as: the ship itself, or for a
  # melted pledge the ship it comes back as.
  def vehicle_start_model
    return if source_vehicle.blank?
    return source_vehicle.model unless start_kind == "melted"

    HangarPlans::MeltedPledge.base_model(source_vehicle)
  end

  # RSI buys a pledge back for what melting it credited. An upgraded pledge
  # comes back as first bought, its upgrades apart, so its price is that of the
  # ship it comes back as, until the user enters what they paid.
  private def melted_price
    melt = source_melt
    return if melt.nil?
    return melt.value if start_model.nil? || start_model.id == source_vehicle.model_id

    start_model.pledge_price
  end

  private def start_changed?
    new_record? || will_save_change_to_start_kind? || will_save_change_to_source_vehicle_id? ||
      will_save_change_to_buyback_pledge_id? || will_save_change_to_start_model_id? ||
      will_save_change_to_bundled_with_id?
  end

  private def assign_start_model
    self.start_model = vehicle_start_model if VEHICLE_KINDS.include?(start_kind) && source_vehicle.present?
    self.start_model ||= candidate&.model if SHIPLESS_KINDS.include?(start_kind)
  end

  private def held_by_a_ship_or_an_empty_slot
    return errors.add(:base, :holder_invalid) if candidate.present? == slot.present?

    errors.add(:base, :holder_invalid) if slot.present? && will_save_change_to_hangar_plan_slot_id? && slot.candidates.exists?
  end

  private def start_model_known
    return if start_model.present?
    return if slot.present? && SHIPLESS_KINDS.include?(start_kind)

    errors.add(:start_model, :required)
  end

  private def start_source
    return if hangar_plan.blank?

    case start_kind
    when "owned"
      if source_vehicle.blank? || hangar_plan.live_vehicles.where(id: source_vehicle.id).none?
        errors.add(:source_vehicle_id, :invalid)
      elsif hangar_plan.melts.where(vehicle_id: source_vehicle_id).exists?
        errors.add(:source_vehicle_id, :melted)
      # Melting one ship of a pledge melts all of it.
      elsif source_vehicle.rsi_pledge_id.present? &&
          hangar_plan.melts.joins(:vehicle).where(vehicles: {rsi_pledge_id: source_vehicle.rsi_pledge_id}).exists?
        errors.add(:source_vehicle_id, :pledge_melted)
      elsif hangar_plan.acquisitions.where(source_vehicle_id:).where.not(id:).exists?
        errors.add(:source_vehicle_id, :taken)
      end
    when "melted"
      if source_vehicle.blank? || hangar_plan.melted_vehicle_ids.exclude?(source_vehicle.id)
        errors.add(:source_vehicle_id, :not_melted)
      elsif melted_pledge_taken?
        errors.add(:source_vehicle_id, :taken)
      end
    when "buyback"
      if buyback_pledge.blank? || buyback_pledge.user_id != hangar_plan.user_id || BUYBACK_SHIP_KINDS.exclude?(buyback_pledge.kind)
        errors.add(:buyback_pledge_id, :invalid)
      elsif buyback_pledge_taken?
        errors.add(:buyback_pledge_id, :taken)
      end
    when "bundled"
      bundled_source
    end

    errors.add(:bundled_with_id, :invalid) if start_kind != "bundled" && bundled_with_id.present?
    errors.add(:source_vehicle_id, :invalid) if VEHICLE_KINDS.exclude?(start_kind) && source_vehicle_id.present?
    errors.add(:buyback_pledge_id, :invalid) if start_kind != "buyback" && buyback_pledge_id.present?
  end

  # One of the other ships of a pledge another start of the plan buys back, and
  # one no other start takes yet.
  private def bundled_source
    if bundled_with.blank? || bundled_with_id == id || bundled_with.hangar_plan_id != hangar_plan_id ||
        BUYBACK_START_KINDS.exclude?(bundled_with.start_kind)
      return errors.add(:bundled_with_id, :invalid)
    end

    held = HangarPlans::BundledShips.for(bundled_with).count { |model| model.id == start_model_id }
    taken = bundled_with.bundled_starts.where(start_model_id:).where.not(id:).count
    errors.add(:start_model, :not_bundled) if held.zero?
    errors.add(:start_model, :taken) if held.positive? && taken >= held
  end

  # A pledge goes back to the hangar once, whichever of its ships names it.
  private def melted_pledge_taken?
    others = hangar_plan.acquisitions.where(start_kind: "melted").where.not(id:)
    return true if others.where(source_vehicle_id:).exists?
    return false if source_vehicle.rsi_pledge_id.blank?

    others.joins(:source_vehicle).where(vehicles: {rsi_pledge_id: source_vehicle.rsi_pledge_id}).exists?
  end

  private def buyback_pledge_taken?
    hangar_plan.acquisitions.where(buyback_pledge_id:).where.not(id:).exists? ||
      hangar_plan.upgrade_steps.where(buyback_pledge_id:).exists?
  end

  private def quantity_available
    taken, quantity = if candidate.present?
      [candidate.acquisitions, candidate.slot.quantity]
    elsif slot.present?
      [slot.starts, slot.quantity]
    end
    return if taken.nil? || taken.where.not(id:).count < quantity

    errors.add(:base, :slot_filled)
  end

  # Each step checks the plan's saved steps; this catches one chain spending the
  # same upgrade more often than the user holds it before any of it is saved.
  private def chain_resources_available
    return if hangar_plan.blank?

    other_steps = hangar_plan.upgrade_steps.where.not(hangar_plan_acquisition_id: id)

    ordered_steps.select { |step| step.source_kind == "owned_ccu" && step.hangar_pledge_item.present? }
      .group_by(&:hangar_pledge_item).each do |item, steps|
        used = other_steps.where(hangar_pledge_item_id: item.id).count
        errors.add(:base, :upgrade_taken) if used + steps.size > item.quantity
      end

    buybacks = ordered_steps.filter_map(&:buyback_pledge_id)
    errors.add(:base, :upgrade_taken) if buybacks.uniq.size != buybacks.size
    errors.add(:base, :upgrade_taken) if buybacks.include?(buyback_pledge_id)
  end

  private def chain_ends_on_candidate
    return errors.add(:base, :chain_mismatch) if candidate.blank? && ordered_steps.any?
    return if candidate.blank? || start_model.blank?

    previous = start_model
    ordered_steps.each do |step|
      errors.add(:base, :chain_broken) if step.from_model_id != previous.id
      previous = step.target_model || previous
    end

    errors.add(:base, :chain_mismatch) if ordered_steps.any? && !route_complete?
  end
end
