# frozen_string_literal: true

# A hangar the user wants to have, planned apart from the one they have. Kept
# out of `vehicles` on purpose: vehicle callbacks create loaners and snub craft,
# sync fleets and broadcast, and dozens of scopes would have to learn to skip
# planned ships.
class HangarPlan < ApplicationRecord
  MAX_PER_USER = 20

  belongs_to :user

  has_many :slots, -> { order(:position, :created_at) },
    class_name: "HangarPlanSlot", inverse_of: :hangar_plan, dependent: :destroy
  has_many :candidates, through: :slots
  has_many :acquisitions, class_name: "HangarPlanAcquisition", inverse_of: :hangar_plan, dependent: :destroy
  has_many :upgrade_steps, class_name: "HangarPlanUpgradeStep", inverse_of: :hangar_plan, dependent: :destroy
  has_many :melts, -> { order(:created_at) },
    class_name: "HangarPlanMelt", inverse_of: :hangar_plan, dependent: :destroy

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validates :description, length: {maximum: 2000}
  validates :starting_credit, numericality: {greater_than_or_equal_to: 0}
  validate :plan_limit, on: :create

  before_validation -> { self.based_on_at ||= Time.current }

  def shared?
    share_token.present?
  end

  def share!
    update!(share_token: SecureRandom.urlsafe_base64(18)) unless shared?
  end

  def unshare!
    update!(share_token: nil)
  end

  # The purchased ships a plan compares against: what a plan started from the
  # hangar copies. Loaners and bundled snub craft come with a ship and are never
  # planned on their own.
  def live_vehicles
    user.vehicles.purchased.where(loaner: false, bundled: false, hidden: false)
  end

  # Asked once per route and melt when a plan renders, so it is held.
  def live_vehicle_ids
    @live_vehicle_ids ||= live_vehicles.pluck(:id).to_set
  end

  def used_vehicle_ids
    acquisitions.where.not(source_vehicle_id: nil).pluck(:source_vehicle_id) + melts.pluck(:vehicle_id)
  end

  private def plan_limit
    return if user.blank?
    return if user.hangar_plans.count < MAX_PER_USER

    errors.add(:base, :plan_limit_reached, count: MAX_PER_USER)
  end
end
