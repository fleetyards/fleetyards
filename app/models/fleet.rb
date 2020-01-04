# frozen_string_literal: true

class Fleet < ApplicationRecord
  has_many :fleet_memberships,
           dependent: :destroy
  has_many :accepted_memberships,
           -> { where.not(accepted_at: nil) },
           class_name: 'FleetMembership',
           inverse_of: false
  has_many :users,
           through: :accepted_memberships
  has_many :public_vehicles,
           through: :users
  has_many :public_models,
           through: :users
  has_many :manufacturers,
           through: :users

  validates :name, presence: true
  validates :name, uniqueness: true

  mount_uploader :logo, LogoUploader
  mount_uploader :background_image, ImageUploader

  accepts_nested_attributes_for :fleet_memberships

  before_save :update_slugs
  after_create :setup_admin_user

  def self.not_declined
    includes(:fleet_memberships).joins(:fleet_memberships)
                                .where(fleet_memberships: { declined_at: nil })
  end

  def setup_admin_user
    fleet_memberships.create(user_id: created_by, role: :admin, accepted_at: Time.zone.now)
  end

  def role(user_id)
    membership = fleet_memberships.find_by(user_id: user_id)

    return if membership.blank? || membership.invitation || membership.declined_at.present?

    membership.role
  end

  def invitation(user_id)
    fleet_memberships.find_by(user_id: user_id)&.invitation
  end

  def accepted_at(user_id)
    fleet_memberships.find_by(user_id: user_id)&.accepted_at
  end

  def model_count(model_id)
    public_vehicles.where(model_id: model_id).size
  end
end
