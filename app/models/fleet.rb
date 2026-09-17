# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id                        :uuid             not null, primary key
#  allies_fleet              :boolean          default(FALSE), not null
#  allies_fleet_members      :boolean          default(FALSE), not null
#  allies_fleet_stats        :boolean          default(FALSE), not null
#  calendar_feed_token       :string
#  created_by                :uuid
#  default_timezone          :string           default("UTC"), not null
#  description               :text
#  discarded_at              :datetime
#  discord                   :string
#  fid                       :string
#  guilded                   :string
#  homepage                  :string
#  inventory_transfer_policy :integer          default(0), not null
#  name                      :string
#  normalized_fid            :string
#  public_fleet              :boolean          default(FALSE)
#  public_fleet_stats        :boolean          default(FALSE)
#  rsi_sid                   :string
#  sid                       :string
#  slug                      :string
#  transfers_blocked_at      :datetime
#  transfers_blocked_reason  :text
#  ts                        :string
#  twitch                    :string
#  youtube                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_fleets_on_calendar_feed_token  (calendar_feed_token) UNIQUE
#  index_fleets_on_discarded_at         (discarded_at)
#  index_fleets_on_fid                  (fid) UNIQUE WHERE (discarded_at IS NULL)
#
class Fleet < ApplicationRecord
  include Discard::Model
  include UrlFieldConcern
  include ActiveStorageVariants
  include InventoryTransferParty

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

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS, meta: {
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

  # The database cascades these, so `dependent:` would only be a second, slower
  # way of doing the same thing -- and a fleet must never fail to delete
  # because of a row describing what it was entitled to.
  has_many :fleet_subscriptions, dependent: nil

  has_many :sent_alliance_requests,
    class_name: "FleetAlliance",
    foreign_key: :requester_id,
    dependent: :destroy,
    inverse_of: :requester
  has_many :received_alliance_requests,
    class_name: "FleetAlliance",
    foreign_key: :addressee_id,
    dependent: :destroy,
    inverse_of: :addressee
  has_many :missions, dependent: :destroy
  has_many :fleet_contracts, dependent: :destroy
  has_many :fleet_events, dependent: :destroy
  # Nullified rather than destroyed: a tour's ledger is the record of who still
  # owes whom, and the people on it are not all in this fleet. Losing the fleet
  # turns one back into the standalone tour its organiser and participants can
  # still settle between themselves.
  has_many :tours, dependent: :nullify
  has_one :fleet_notification_setting, dependent: :destroy
  has_many :fleet_vehicles, dependent: :destroy
  has_many :vehicles, through: :fleet_vehicles, source: :vehicle
  has_many :models, through: :vehicles, source: :model
  has_many :manufacturers,
    through: :models

  validates :fid,
    uniqueness: {case_sensitive: false, conditions: -> { where(discarded_at: nil) }},
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

  # A cover per contract kind, so a fleet's board carries its own art rather
  # than the stand-ins `useContractCover` falls back to. One attachment each
  # rather than a table: the kinds are a fixed enum of three, and this is the
  # shape the logo and the background already use.
  has_one_attached :transport_contract_cover
  has_one_attached :procurement_contract_cover
  has_one_attached :crafting_contract_cover

  CONTRACT_COVER_ATTACHMENTS = {
    "transport" => :transport_contract_cover,
    "procurement" => :procurement_contract_cover,
    "crafting" => :crafting_contract_cover
  }.freeze

  validates :logo, :background_image,
    :transport_contract_cover, :procurement_contract_cover, :crafting_contract_cover,
    no_vector_image: true

  def contract_cover_for(kind)
    attachment = CONTRACT_COVER_ATTACHMENTS[kind.to_s]

    public_send(attachment) if attachment.present?
  end

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

  # Every fleet this one has an accepted alliance with. Scoped `.kept`: a fleet
  # is soft-deleted, so its alliances outlive it, and one with a discarded fleet
  # must admit nothing -- while staying intact if that fleet is restored.
  def allies
    ::Fleet.kept.where(id: ::FleetAlliance.partner_ids_for(self))
  end

  def allied_with?(other)
    return false if other.blank? || other.discarded?

    ::FleetAlliance.accepted_between?(self, other)
  end

  def alliance_with(other)
    ::FleetAlliance.between(self, other)
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

  # Every flag enabled for this fleet as a Flipper actor — deliberately not the
  # ones a member enabled for themselves, so a fleet page can tell whether a
  # feature is on for *this* fleet rather than for any fleet the viewer is in.
  # Memoised per instance, and that is not a detail. `#features` above iterates
  # every flag in the registry per request and `Frontend::BaseController` does
  # the same, so an entitlement read reached from inside either loop would
  # multiply by the flag count. Asserted with a query-count test.
  def subscribed?(date = Date.current)
    return @subscribed[date] if defined?(@subscribed) && @subscribed.key?(date)

    @subscribed ||= {}
    @subscribed[date] = fleet_subscriptions.active_on(date).exists?
  end

  # The row itself, for anything that needs to say *why* -- an admin screen, or
  # a notification naming what lapsed.
  def active_subscription(date = Date.current)
    return @active_subscription[date] if defined?(@active_subscription) && @active_subscription.key?(date)

    @active_subscription ||= {}
    @active_subscription[date] = fleet_subscriptions.active_on(date).first
  end

  def features
    Flipper.features.filter_map do |feature|
      Flipper.enabled?(feature.name, self) ? feature.name.to_s : nil
    end
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
