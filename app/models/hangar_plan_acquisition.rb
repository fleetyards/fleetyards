# frozen_string_literal: true

# How one ship of a slot is obtained: kept from the hangar, bought on the
# store or in game, or bought back, then optionally upgraded step by step until
# it is the planned ship. The start and every step are resources the user owns
# at most once, so nothing here may be spent twice within a plan.
class HangarPlanAcquisition < ApplicationRecord
  START_KINDS = %w[owned store ingame buyback].freeze
  BUYBACK_SHIP_KINDS = %w[ship package other].freeze

  belongs_to :hangar_plan, touch: true
  belongs_to :candidate, class_name: "HangarPlanCandidate", foreign_key: :hangar_plan_candidate_id,
    inverse_of: :acquisitions
  belongs_to :start_model, class_name: "Model"
  belongs_to :source_vehicle, class_name: "Vehicle", optional: true
  belongs_to :buyback_pledge, optional: true

  has_many :upgrade_steps, -> { order(:position) },
    class_name: "HangarPlanUpgradeStep", inverse_of: :acquisition, dependent: :destroy

  validates :start_kind, inclusion: {in: START_KINDS}
  validates :price_override, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :start_source
  validate :quantity_available, on: :create
  validate :chain_ends_on_candidate
  validate :chain_resources_available

  before_validation :assign_start_model
  before_create -> { self.price_snapshot ||= list_price }

  def final_model
    ordered_steps.last&.target_model || start_model
  end

  # Loaded rather than queried, so steps built for an unsaved chain count too.
  def ordered_steps
    upgrade_steps.to_a.reject(&:marked_for_destruction?).sort_by(&:position)
  end

  # What starting this way costs today, before an override: an owned ship cost
  # nothing more, an in-game purchase costs no USD.
  def list_price
    case start_kind
    when "owned", "ingame" then 0
    when "store" then start_model&.pledge_price
    when "buyback" then buyback_pledge&.price
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
    else false
    end
  end

  def source_changed?
    start_kind == "owned" && live_source_vehicle.present? && live_source_vehicle.model_id != start_model_id
  end

  def live_source_vehicle
    return if source_vehicle.blank?

    source_vehicle if hangar_plan.live_vehicle_ids.include?(source_vehicle.id)
  end

  private def assign_start_model
    self.start_model_id = source_vehicle.model_id if start_kind == "owned" && source_vehicle.present? && start_model_id.blank?
  end

  private def start_source
    return if hangar_plan.blank?

    case start_kind
    when "owned"
      if source_vehicle.blank? || hangar_plan.live_vehicles.where(id: source_vehicle.id).none?
        errors.add(:source_vehicle_id, :invalid)
      elsif hangar_plan.melts.where(vehicle_id: source_vehicle_id).exists?
        errors.add(:source_vehicle_id, :melted)
      elsif hangar_plan.acquisitions.where(source_vehicle_id:).where.not(id:).exists?
        errors.add(:source_vehicle_id, :taken)
      end
    when "buyback"
      if buyback_pledge.blank? || buyback_pledge.user_id != hangar_plan.user_id || BUYBACK_SHIP_KINDS.exclude?(buyback_pledge.kind)
        errors.add(:buyback_pledge_id, :invalid)
      elsif buyback_pledge_taken?
        errors.add(:buyback_pledge_id, :taken)
      end
    end

    errors.add(:source_vehicle_id, :invalid) if start_kind != "owned" && source_vehicle_id.present?
    errors.add(:buyback_pledge_id, :invalid) if start_kind != "buyback" && buyback_pledge_id.present?
  end

  private def buyback_pledge_taken?
    hangar_plan.acquisitions.where(buyback_pledge_id:).where.not(id:).exists? ||
      hangar_plan.upgrade_steps.where(buyback_pledge_id:).exists?
  end

  private def quantity_available
    return if candidate.blank?
    return if candidate.acquisitions.count < candidate.slot.quantity

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
    return if candidate.blank? || start_model.blank?

    previous = start_model
    ordered_steps.each do |step|
      errors.add(:base, :chain_broken) if step.from_model_id != previous.id
      previous = step.target_model || previous
    end

    errors.add(:base, :chain_mismatch) if final_model&.id != candidate.model_id
  end
end
