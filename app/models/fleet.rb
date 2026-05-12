# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id                  :uuid             not null, primary key
#  calendar_feed_token :string
#  created_by          :uuid
#  default_timezone    :string           default("UTC"), not null
#  description         :text
#  discord             :string
#  fid                 :string
#  guilded             :string
#  homepage            :string
#  name                :string
#  normalized_fid      :string
#  public_fleet        :boolean          default(FALSE)
#  public_fleet_stats  :boolean          default(FALSE)
#  rsi_sid             :string
#  sid                 :string
#  slug                :string
#  ts                  :string
#  twitch              :string
#  youtube             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_fleets_on_calendar_feed_token  (calendar_feed_token) UNIQUE
#  index_fleets_on_fid                  (fid) UNIQUE
#
class Fleet < ApplicationRecord
  include UrlFieldConcern
  include ActiveStorageVariants

  attr_accessor :update_reason, :update_reason_description, :author_id

  AVAILABLE_PRIVILEGES = [
    "fleet:update",
    "fleet:update:images",
    "fleet:update:description",
    "fleet:delete",
    "fleet:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: ["fleet:manage"],
    officer: ["fleet:update:description", "fleet:update:images"],
    member: []
  }.freeze

  has_paper_trail meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  has_many :fleet_roles,
    dependent: :destroy
  has_many :fleet_memberships,
    dependent: :destroy
  has_many :fleet_invite_urls,
    dependent: :destroy
  has_many :fleet_inventories, dependent: :destroy
  has_many :missions, dependent: :destroy
  has_many :fleet_events, dependent: :destroy
  has_one :fleet_notification_setting, dependent: :destroy
  has_many :fleet_vehicles, dependent: :destroy
  has_many :vehicles, through: :fleet_vehicles, source: :vehicle
  has_many :models, through: :vehicles, source: :model
  has_many :manufacturers,
    through: :models

  validates :fid,
    uniqueness: {case_sensitive: false},
    length: {minimum: 3},
    presence: true,
    format: {with: /\A[a-zA-Z0-9\-_]{3,}\Z/}

  validates :name,
    length: {minimum: 3},
    presence: true,
    format: {with: /\A[a-zA-Z0-9\-_. ]{3,}\Z/}

  validates :description,
    format: {
      with: /^[\d\w\bÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚàâæçéèêëïîôœùûüÿäöáíñóú\[\]()\-_'".,?!:;\s]*$/,
      multiline: true
    }

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = ["name asc", "name desc", "createdAt asc", "createdAt desc"]

  def self.ransackable_attributes(auth_object = nil)
    [
      "created_at", "created_by", "description", "fid", "id", "id_value",
      "name", "normalized_fid", "public_fleet", "public_fleet_stats",
      "slug", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  has_one_attached :logo
  has_one_attached :background_image

  accepts_nested_attributes_for :fleet_memberships

  before_validation :update_urls
  before_validation :set_normalized_fields
  before_save :update_slugs
  after_create :setup_default_roles!
  after_create :setup_admin_user

  def self.accepted
    includes(:fleet_memberships).joins(:fleet_memberships)
      .where(fleet_memberships: {aasm_state: :accepted})
  end

  def set_normalized_fields
    self.normalized_fid = fid&.downcase
  end

  def update_urls(force: false)
    %i[discord twitch youtube homepage guilded].each do |field|
      send(:"#{field}=", ensure_valid_url(self, field, force:))
    end

    self.ts = ensure_valid_ts_url(self, :ts, force:)
  end

  def setup_default_roles!
    FleetRole.setup_default_roles!(self)
  end

  def default_member_role
    fleet_roles.ranked.last || begin
      setup_default_roles!
      fleet_roles.reload.ranked.last
    end
  end

  def setup_admin_user
    fleet_memberships.create(
      user_id: created_by,
      fleet_role: fleet_roles.ranked.first,
      aasm_state: :accepted,
      accepted_at: Time.zone.now
    )
  end

  def update_role_privileges
    fleet.fleet_roles.each do |role|
    end
  end

  def invitation(user_id)
    fleet_memberships.find_by(user_id:)&.invited?
  end

  def requested(user_id)
    fleet_memberships.find_by(user_id:)&.requested?
  end

  def primary(user_id)
    fleet_memberships.find_by(user_id:)&.primary
  end

  def ships_filter(user_id)
    fleet_memberships.find_by(user_id:)&.ships_filter
  end

  def hangar_group_id(user_id)
    fleet_memberships.find_by(user_id:)&.hangar_group_id
  end

  def accepted_at(user_id)
    fleet_memberships.find_by(user_id:)&.accepted_at
  end

  def model_count(model_id)
    vehicles.where(model_id:, loaner: false).size
  end

  def calendar_feed_enabled?
    calendar_feed_token.present?
  end

  def ensure_calendar_feed_token!
    return calendar_feed_token if calendar_feed_token.present?

    update_column(:calendar_feed_token, self.class.generate_calendar_feed_token)
    calendar_feed_token
  end

  def rotate_calendar_feed_token!
    update_column(:calendar_feed_token, self.class.generate_calendar_feed_token)
    calendar_feed_token
  end

  def clear_calendar_feed_token!
    update_column(:calendar_feed_token, nil)
  end

  def self.generate_calendar_feed_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless exists?(calendar_feed_token: token)
    end
  end

  private def update_slugs
    self.slug = generate_slug(fid)
  end
end
