# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id               :uuid             not null, primary key
#  background_image :string
#  created_by       :uuid
#  description      :text
#  discord          :string
#  fid              :string
#  guilded          :string
#  homepage         :string
#  logo             :string
#  name             :string
#  public_fleet     :boolean          default(FALSE)
#  rsi_sid          :string
#  sid              :string
#  slug             :string
#  ts               :string
#  twitch           :string
#  youtube          :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_fleets_on_fid  (fid) UNIQUE
#
class Fleet < ApplicationRecord
  include UrlFieldHelper

  has_many :fleet_memberships,
           dependent: :destroy
  has_many :fleet_invite_urls,
           dependent: :destroy
  has_many :visible_memberships,
           -> { where(aasm_state: :accepted).where.not(ships_filter: :hide) },
           dependent: :destroy,
           class_name: 'FleetMembership',
           inverse_of: false
  has_many :users,
           through: :visible_memberships

  validates :fid,
            uniqueness: { case_sensitive: false },
            length: { minimum: 3 },
            presence: true,
            format: { with: /\A[a-zA-Z0-9\-_]{3,}\Z/ }
  validates :name,
            length: { minimum: 3 },
            presence: true,
            format: { with: /\A[a-zA-Z0-9\-_. ]{3,}\Z/ }

  validates :description,
            format: {
              with: %r{^[0-9A-ZÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚ\-_'".,?!:;/\s]*$},
              multiline: true
            }

  mount_uploader :logo, LogoUploader
  mount_uploader :background_image, ImageUploader

  accepts_nested_attributes_for :fleet_memberships

  before_validation :update_urls
  before_save :update_slugs
  after_create :setup_admin_user

  def self.accepted
    includes(:fleet_memberships).joins(:fleet_memberships)
      .where(fleet_memberships: { aasm_state: :accepted })
  end

  def update_urls(force: false)
    %i[discord twitch youtube homepage guilded].each do |field|
      send("#{field}=", ensure_valid_url(self, field, force: force))
    end

    self.ts = ensure_valid_ts_url(self, :ts, force: force)
  end

  def vehicles(filters = nil)
    vehicle_ids = visible_memberships.map { |member| member.visible_vehicle_ids(filters) }.flatten

    Vehicle.where(id: vehicle_ids)
  end

  def models(filters = nil)
    model_ids = visible_memberships.map { |member| member.visible_model_ids(filters) }.flatten

    Model.where(id: model_ids)
  end

  def manufacturers
    manufacturer_ids = models.pluck(:manufacturer_id)

    Manufacturer.where(id: manufacturer_ids)
  end

  def setup_admin_user
    fleet_memberships.create(user_id: created_by, role: :admin, aasm_state: :accepted, accepted_at: Time.zone.now)
  end

  def role(user_id)
    membership = fleet_memberships.find_by(user_id: user_id)

    return if membership.blank? || !membership.accepted?

    membership.role
  end

  def my_fleet?(user_id)
    membership = fleet_memberships.find_by(user_id: user_id)

    membership.present? && membership.accepted?
  end

  def invitation(user_id)
    fleet_memberships.find_by(user_id: user_id)&.invited?
  end

  def requested(user_id)
    fleet_memberships.find_by(user_id: user_id)&.requested?
  end

  def primary(user_id)
    fleet_memberships.find_by(user_id: user_id)&.primary
  end

  def ships_filter(user_id)
    fleet_memberships.find_by(user_id: user_id)&.ships_filter
  end

  def hangar_group_id(user_id)
    fleet_memberships.find_by(user_id: user_id)&.hangar_group_id
  end

  def accepted_at(user_id)
    fleet_memberships.find_by(user_id: user_id)&.accepted_at
  end

  def model_count(model_id)
    vehicles.where(model_id: model_id, loaner: false).size
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(fid)
  end
end
