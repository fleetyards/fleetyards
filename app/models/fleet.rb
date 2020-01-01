# frozen_string_literal: true

class Fleet < ApplicationRecord
  has_many :fleet_memberships,
           dependent: :destroy
  has_many :users,
           through: :fleet_memberships
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

  def setup_admin_user
    fleet_memberships.create(accepted: true, user_id: created_by, role: :admin)
  end

  def role(user)
    fleet_memberships.find_by(user_id: user.id)&.role
  end

  def accepted(user)
    fleet_memberships.find_by(user_id: user.id)&.accepted
  end

  def model_count(model_id)
    public_vehicles.where(model_id: model_id).size
  end
end
