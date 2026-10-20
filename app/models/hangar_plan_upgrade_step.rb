# frozen_string_literal: true

# One upgrade (CCU) in an acquisition chain, from one ship to the next. Paid on
# the store, taken from an unapplied upgrade already in the user's RSI hangar,
# or bought back.
class HangarPlanUpgradeStep < ApplicationRecord
  SOURCE_KINDS = %w[store owned_ccu buyback].freeze

  belongs_to :hangar_plan
  belongs_to :acquisition, class_name: "HangarPlanAcquisition", foreign_key: :hangar_plan_acquisition_id,
    inverse_of: :upgrade_steps
  belongs_to :origin_model, class_name: "Model", foreign_key: :from_model_id
  belongs_to :target_model, class_name: "Model", foreign_key: :to_model_id
  belongs_to :hangar_pledge_item, optional: true
  belongs_to :buyback_pledge, optional: true

  validates :source_kind, inclusion: {in: SOURCE_KINDS}
  validates :price_override, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :distinct_models
  validate :upgrade_source

  before_validation -> { self.hangar_plan ||= acquisition&.hangar_plan }
  before_create -> { self.price_snapshot ||= list_price }

  # An upgrade costs the difference between both ships' store prices, as
  # buying one back does. One the user already holds cost nothing more.
  def list_price
    case source_kind
    when "owned_ccu" then 0
    when "store" then store_difference
    when "buyback" then buyback_pledge&.upgrade_price || store_difference
    end
  end

  def price
    price_override || list_price
  end

  def snapshot_price
    price_override || price_snapshot
  end

  def source_missing?
    case source_kind
    when "owned_ccu" then hangar_pledge_item.nil? || hangar_pledge_item.user_id != hangar_plan.user_id
    when "buyback" then buyback_pledge.nil? || buyback_pledge.user_id != hangar_plan.user_id
    else false
    end
  end

  private def store_difference
    from_price = origin_model&.pledge_price
    to_price = target_model&.pledge_price
    return if from_price.nil? || to_price.nil?

    to_price - from_price
  end

  private def distinct_models
    errors.add(:to_model_id, :same_as_from) if from_model_id.present? && from_model_id == to_model_id
  end

  private def upgrade_source
    return if hangar_plan.blank?

    case source_kind
    when "owned_ccu"
      if hangar_pledge_item.blank? || hangar_pledge_item.user_id != hangar_plan.user_id || hangar_pledge_item.kind != "ccu"
        errors.add(:hangar_pledge_item_id, :invalid)
      elsif hangar_plan.upgrade_steps.where(hangar_pledge_item_id:).where.not(id:).count >= hangar_pledge_item.quantity
        errors.add(:hangar_pledge_item_id, :taken)
      end
    when "buyback"
      if buyback_pledge.blank? || buyback_pledge.user_id != hangar_plan.user_id || buyback_pledge.kind != "upgrade"
        errors.add(:buyback_pledge_id, :invalid)
      elsif hangar_plan.upgrade_steps.where(buyback_pledge_id:).where.not(id:).exists?
        errors.add(:buyback_pledge_id, :taken)
      end
    end

    errors.add(:hangar_pledge_item_id, :invalid) if source_kind != "owned_ccu" && hangar_pledge_item_id.present?
    errors.add(:buyback_pledge_id, :invalid) if source_kind != "buyback" && buyback_pledge_id.present?
  end
end
