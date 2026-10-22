# frozen_string_literal: true

# Something the user wants their hangar to cover, such as "main hauler" or
# "3 escort fighters". With no candidate it is a gap, with one it is decided,
# and with several the user has not picked yet.
class HangarPlanSlot < ApplicationRecord
  MAX_PER_PLAN = 200
  MAX_QUANTITY = 99
  STATES = %w[open decided undecided].freeze

  # What the ships for this slot have to be, in the catalogue's own filter
  # terms, so the picker can be opened on them as they stand.
  LIST_FILTERS = %w[classification_in focus_in size_in manufacturer_in production_status_in].freeze
  NUMBER_FILTERS = %w[pledge_price_gteq pledge_price_lteq cargo_gteq].freeze
  BOOLEAN_FILTERS = %w[on_sale_eq].freeze
  FILTERS = (LIST_FILTERS + NUMBER_FILTERS + BOOLEAN_FILTERS).freeze

  belongs_to :hangar_plan, touch: true

  has_many :candidates, -> { order(:position, :created_at) },
    class_name: "HangarPlanCandidate", inverse_of: :slot, dependent: :destroy

  validates :label, presence: true, length: {maximum: 100}
  validates :description, length: {maximum: 2000}
  validate :filters_known
  validates :quantity, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY}
  validate :slot_limit, on: :create
  validate :quantity_covers_routes, on: :update

  before_validation :normalize_filters
  before_create :append_position

  def state
    case candidates.size
    when 0 then "open"
    when 1 then "decided"
    else "undecided"
    end
  end

  def decided_candidate
    candidates.first if state == "decided"
  end

  # Whether a ship meets every filter the slot sets. A ship can be planned
  # outside them; the editor only points it out.
  def matches?(model)
    filters.all? do |key, value|
      case key
      when "classification_in" then value.include?(model.classification)
      when "focus_in" then Model.focus_keys(value).intersect?(model.foci)
      when "size_in" then value.include?(model.size)
      when "manufacturer_in" then value.include?(model.manufacturer&.slug)
      when "production_status_in" then value.include?(model.production_status)
      when "pledge_price_gteq" then model.pledge_price.present? && model.pledge_price >= value
      when "pledge_price_lteq" then model.pledge_price.present? && model.pledge_price <= value
      when "cargo_gteq" then model.cargo.to_f >= value
      when "on_sale_eq" then model.on_sale == value
      else true
      end
    end
  end

  private def normalize_filters
    self.filters = (filters || {}).to_h.stringify_keys.filter_map do |key, value|
      value = case key
      when *LIST_FILTERS then Array(value).compact_blank.map(&:to_s).presence
      when *NUMBER_FILTERS then (value.to_s.strip == "") ? nil : (Float(value.to_s, exception: false) || value)
      when *BOOLEAN_FILTERS then value.nil? ? nil : ActiveModel::Type::Boolean.new.cast(value)
      else value
      end
      [key, value] unless value.nil?
    end.to_h
  end

  private def filters_known
    filters.each do |key, value|
      valid = case key
      when *LIST_FILTERS then value.is_a?(Array)
      when *NUMBER_FILTERS then value.is_a?(Numeric) && value >= 0
      when *BOOLEAN_FILTERS then [true, false].include?(value)
      else false
      end
      errors.add(:filters, :invalid) unless valid
    end
  end

  # Routes beyond the quantity would still hold on to the ships and upgrades
  # they spend, so they have to go first.
  private def quantity_covers_routes
    return unless quantity_changed?

    routes = HangarPlanAcquisition.where(hangar_plan_candidate_id: candidates.select(:id))
      .group(:hangar_plan_candidate_id).count.values.max || 0
    errors.add(:quantity, :below_routes, count: routes) if quantity.to_i < routes
  end

  private def slot_limit
    return if hangar_plan.blank?
    return if hangar_plan.slots.count < MAX_PER_PLAN

    errors.add(:base, :slot_limit_reached, count: MAX_PER_PLAN)
  end

  private def append_position
    self.position = (hangar_plan.slots.maximum(:position) || -1) + 1 if position.zero?
  end
end
