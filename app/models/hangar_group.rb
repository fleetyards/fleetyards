# frozen_string_literal: true

class HangarGroup < ApplicationRecord
  belongs_to :user

  has_many :task_forces, dependent: :destroy
  has_many :vehicles, through: :task_forces

  validates :name, :color, presence: true
  validates :name, uniqueness: {scope: :user_id}

  before_save :update_slugs
  after_save :touch_vehicles
  after_commit :broadcast_update

  def self.ransackable_attributes(auth_object = nil)
    ["color", "created_at", "id", "id_value", "name", "public", "slug", "sort", "updated_at", "user_id"]
  end

  def broadcast_update
    HangarChannel.broadcast_to(user, {hangarGroupId: id})
  end

  private def touch_vehicles
    vehicles.update_all(updated_at: Time.zone.now)
  end
end
