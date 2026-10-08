# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id                          :uuid             not null, primary key
#  alignment                   :string
#  allies_fleet                :boolean          default(FALSE), not null
#  allies_fleet_members        :boolean          default(FALSE), not null
#  allies_fleet_stats          :boolean          default(FALSE), not null
#  calendar_feed_token         :string
#  commitment                  :string
#  created_by                  :uuid
#  default_timezone            :string           default("UTC"), not null
#  description                 :text
#  discarded_at                :datetime
#  discord                     :string
#  fid                         :string
#  guilded                     :string
#  headquarters                :string
#  homepage                    :string
#  inventory_transfer_policy   :integer          default("everyone"), not null
#  language                    :string
#  listed                      :boolean
#  name                        :string
#  normalized_fid              :string
#  primary_activity            :string
#  public_fleet                :boolean          default(FALSE)
#  public_fleet_stats          :boolean          default(FALSE)
#  recruiting                  :boolean
#  roleplay                    :boolean
#  rsi_member_count            :integer
#  rsi_sid                     :string
#  rsi_sync_attempted_at       :datetime
#  rsi_synced_at               :datetime
#  rsi_verification_checked_at :datetime
#  rsi_verification_status     :string
#  rsi_verification_token      :string
#  rsi_verified_at             :datetime
#  rsi_verified_sid            :string
#  secondary_activity          :string
#  sid                         :string
#  slug                        :string
#  squadrons_enabled           :boolean          default(FALSE), not null
#  transfers_blocked_at        :datetime
#  transfers_blocked_reason    :text
#  ts                          :string
#  twitch                      :string
#  youtube                     :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  headquarters_location_id    :uuid
#
# Indexes
#
#  index_fleets_on_calendar_feed_token       (calendar_feed_token) UNIQUE
#  index_fleets_on_discarded_at              (discarded_at)
#  index_fleets_on_fid                       (fid) UNIQUE WHERE (discarded_at IS NULL)
#  index_fleets_on_headquarters_location_id  (headquarters_location_id)
#  index_fleets_on_rsi_verified_sid          (rsi_verified_sid) UNIQUE WHERE (discarded_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (headquarters_location_id => locations.id) ON DELETE => nullify
#
class Fleet < ApplicationRecord
  include Discard::Model
  include UrlFieldConcern
  include ActiveStorageVariants
  include InventoryTransferParty
  include LinkedLocations
  include FeatureFlagActor

  # Where the fleet is based: free text, linked to one of our places where it
  # is one.
  links_location :headquarters, foreign_key: :headquarters_location_id, as: :headquarters_location

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

  before_destroy :preserve_payout_participant_names, prepend: true

  has_many :fleet_roles,
    dependent: :destroy
  has_many :fleet_memberships,
    dependent: :destroy
  has_many :fleet_invite_urls,
    dependent: :destroy
  has_many :fleet_discord_role_holders, dependent: :delete_all
  has_many :fleet_inventories, dependent: :destroy
  # Ordered here rather than at every call site: the strip on the front page,
  # the filter segments and the roster badges all read this association, and a
  # custom order that only the list page honoured would not be one.
  has_many :fleet_squadrons, -> { order(rank: :asc) }, dependent: :destroy
  # After the squadrons: their memberships hold the ranks, and the foreign key
  # refuses a rank that is still held.
  has_many :fleet_squadron_roles, -> { order(position: :asc) }, dependent: :destroy

  # The database cascades these, so `dependent:` would only be a second, slower
  # way of doing the same thing -- and a fleet must never fail to delete
  # because of a row describing what it was entitled to.
  has_many :fleet_subscriptions, dependent: nil
  has_many :outgoing_fid_claims, class_name: "FleetFidClaim", foreign_key: :claimant_id,
    dependent: nil, inverse_of: :claimant
  has_many :incoming_fid_claims, class_name: "FleetFidClaim", foreign_key: :holder_id,
    dependent: nil, inverse_of: :holder

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
  # Nullified for the same reason: a ledger the fleet paid into still has to
  # add up, so the row keeps the fleet's name and becomes a named guest.
  has_many :payout_participants, dependent: :nullify
  has_one :fleet_notification_setting, dependent: :destroy
  has_many :fleet_vehicles, dependent: :destroy
  has_many :vehicles, through: :fleet_vehicles, source: :vehicle
  has_many :models, through: :vehicles, source: :model
  has_many :manufacturers,
    through: :models

  FID_FORMAT = /\A[a-zA-Z0-9\-_]{3,}\Z/

  validates :fid,
    uniqueness: {case_sensitive: false, conditions: -> { where(discarded_at: nil) }},
    length: {minimum: 3},
    presence: true,
    format: {with: FID_FORMAT}

  validate :fid_not_reserved, if: :fid_changed?

  normalizes :rsi_sid, with: ->(sid) { Rsi::Sid.normalize(sid) }

  # Only on change: a row saved before the column was checked must not block an
  # unrelated edit of the fleet.
  validates :rsi_sid,
    format: {with: Rsi::Sid::FORMAT, message: :not_an_rsi_sid},
    allow_nil: true,
    if: :rsi_sid_changed?

  # A proved SID stays put: it names the org the fleet showed it runs, and its
  # members' flags were earned against it. An admin revoke is the way out.
  validate :verified_rsi_sid_locked, if: :rsi_sid_changed?

  RSI_VERIFICATION_COOLDOWN = 1.minute

  enum :rsi_verification_status, {
    pending: "pending",
    verified: "verified",
    token_missing: "token_missing",
    symbol_mismatch: "symbol_mismatch",
    not_found: "not_found",
    failed: "failed"
  }, prefix: :rsi_verification

  before_create -> { self.rsi_verification_token ||= self.class.new_rsi_verification_token }
  before_save :reset_rsi_verification, if: :rsi_sid_changed?
  after_update :sync_membership_verification, if: :saved_change_to_rsi_sid?
  # The index keeps one verified SID per kept fleet, so a discarded fleet has to
  # let go of it: restoring one would otherwise collide with whoever proved the
  # SID since.
  before_discard :reset_rsi_verification
  after_discard -> { FleetFidClaim.cancel_for_lost_verification!(self) }

  validates :name,
    length: {minimum: 3},
    presence: true,
    format: {with: /\A[a-zA-Z0-9\-_. ]{3,}\Z/}

  # A ceiling well clear of anything anybody has written -- the longest
  # description on record is a little over 5000 characters -- so it bounds the
  # column without invalidating a fleet that is already there. The form draws
  # the same number as a running count.
  #
  # No character whitelist: the description is markdown and the page renders it
  # escaped, so the characters it may hold are not what keeps it safe.
  validates :description, length: {maximum: 10_000}

  ALIGNMENTS = BlueprintSource::ALIGNMENTS
  ACTIVITIES = Rsi::OrgAttributes::ACTIVITIES.keys.freeze
  COMMITMENTS = Rsi::OrgAttributes::COMMITMENTS.keys.freeze

  validates :alignment, inclusion: {in: ALIGNMENTS}, allow_nil: true
  validates :primary_activity, :secondary_activity, inclusion: {in: ACTIVITIES}, allow_nil: true
  validates :commitment, inclusion: {in: COMMITMENTS}, allow_nil: true
  validates :language, inclusion: {in: Rsi::Languages::CODES}, allow_nil: true
  validate :secondary_activity_differs, if: -> { secondary_activity.present? }

  # The routes under /fleets/ that are not a fleet: a fleet given one of these
  # FIDs would be shadowed by the page of the same name.
  RESERVED_SLUGS = %w[add preview invites directory].freeze

  validate :fid_not_a_route_name, if: :fid_changed?

  DIRECTORY_MEMBER_FLOOR = 2

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = ["name asc", "name desc", "createdAt asc", "createdAt desc"]
  DIRECTORY_SORTING_PARAMS = ALLOWED_SORTING_PARAMS + ["memberCount asc", "memberCount desc"]
  ADMIN_SORTING_PARAMS = DIRECTORY_SORTING_PARAMS + [
    "fid asc", "fid desc", "updatedAt asc", "updatedAt desc", "rsiMemberCount asc", "rsiMemberCount desc"
  ]

  def self.accepted_member_count_sql
    <<~SQL.squish
      (SELECT COUNT(*) FROM fleet_memberships
        WHERE fleet_memberships.fleet_id = fleets.id
          AND fleet_memberships.aasm_state = 'accepted'
          AND fleet_memberships.discarded_at IS NULL)
    SQL
  end

  ransacker :member_count, type: :integer do
    Arel.sql(accepted_member_count_sql)
  end

  # A fleet RSI has not answered for yet sorts and filters as an empty org,
  # rather than ahead of every other one in a descending sort.
  ransacker :rsi_member_count, type: :integer do
    Arel.sql("COALESCE(fleets.rsi_member_count, 0)")
  end

  # A verified SID is a query rather than a flag: a revoke and a takeover write
  # their columns past the callbacks, and a fleet that loses its verification,
  # goes private or drops below the floor has to leave without anyone touching
  # its `listed` choice. `listed` is nil until a manager picks, and nil follows
  # `public_fleet`, which this already requires.
  scope :rsi_verified, -> { where.not(rsi_verified_at: nil).where("fleets.rsi_verified_sid = fleets.rsi_sid") }

  # The scope above as a boolean, so a filter can ask for the unverified ones
  # too. COALESCE because a fleet without a SID compares to NULL, not false.
  ransacker :rsi_verified, type: :boolean do
    Arel.sql(<<~SQL.squish)
      COALESCE(fleets.rsi_verified_at IS NOT NULL AND fleets.rsi_verified_sid = fleets.rsi_sid, FALSE)
    SQL
  end

  ransacker :created_on, type: :date do
    Arel.sql("DATE(fleets.created_at)")
  end

  scope :directory, -> {
    kept
      .rsi_verified
      .where(public_fleet: true)
      .where(listed: [nil, true])
      .where(id: FleetMembership.kept.accepted
        .group(:fleet_id)
        .having("COUNT(*) >= ?", DIRECTORY_MEMBER_FLOOR)
        .select(:fleet_id))
  }

  def self.with_member_count
    select(arel_table[Arel.star], Arel.sql("#{accepted_member_count_sql} AS member_count"))
  end

  # Name or SID, ranked for a picker: an exact match first, then the ones that
  # start with the term, then those that merely contain it, alphabetical within
  # each. Contains-only in name order buried a fleet called "Test" behind ~370
  # others with "test" somewhere in them.
  def self.search_ranked(term)
    needle = term.to_s.strip.downcase
    escaped = sanitize_sql_like(needle)
    rank = sanitize_sql_array([<<~SQL.squish, {exact: needle, prefix: "#{escaped}%"}])
      CASE
        WHEN LOWER(fleets.name) = :exact OR LOWER(fleets.fid) = :exact THEN 0
        WHEN LOWER(fleets.name) LIKE :prefix OR LOWER(fleets.fid) LIKE :prefix THEN 1
        ELSE 2
      END
    SQL

    where("LOWER(fleets.name) LIKE :contains OR LOWER(fleets.fid) LIKE :contains", contains: "%#{escaped}%")
      .reorder(Arel.sql(rank), Arel.sql("LOWER(fleets.name)"), :id)
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "alignment", "commitment", "created_at", "created_by", "created_on", "default_timezone",
      "description", "fid", "id", "id_value", "language", "member_count",
      "name", "normalized_fid", "primary_activity", "public_fleet",
      "public_fleet_stats", "recruiting", "roleplay", "rsi_member_count", "rsi_verified", "rsi_verified_sid",
      "secondary_activity", "slug", "updated_at"
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
  after_create :setup_default_squadron_roles!
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

  # For fragment keys: `updated_at` keeps whole seconds, and two verifications
  # inside one second -- even of two different SIDs -- must not share a key.
  def rsi_verification_cache_key
    [rsi_verified_sid, rsi_verified_at&.utc&.iso8601(6)]
  end

  def rsi_verified?
    rsi_verified_at.present? && rsi_sid.present? && rsi_verified_sid == rsi_sid
  end

  # `with_member_count` answers from the row, which is what keeps a directory
  # page from counting each fleet's roster with a query of its own.
  def member_count
    return self[:member_count] if has_attribute?(:member_count)

    fleet_memberships.kept.accepted.count
  end

  def listed_in_directory?
    kept? && public_fleet? && rsi_verified? && listed != false &&
      member_count >= DIRECTORY_MEMBER_FLOOR
  end

  # The public API names the org only once the fleet has shown it runs it:
  # anyone can type any SID.
  def public_rsi_sid
    rsi_sid if rsi_verified?
  end

  # Only the sync of a verified org writes the count, and a revoke leaves the
  # last one behind.
  def verified_rsi_member_count
    rsi_member_count if rsi_verified?
  end

  # Written past validation: neither column is something a form edits, and a
  # fleet saved before a later format check must still be able to get a token.
  # rubocop:disable Rails/SkipsModelValidations
  # Not a secret: it is meant to be pasted on a public page, and all it can
  # ever prove is that this fleet's managers reached that page.
  def self.new_rsi_verification_token
    "FLEETYARDS-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def generate_rsi_verification_token!
    update_columns(
      rsi_verification_token: self.class.new_rsi_verification_token,
      rsi_verification_status: nil,
      updated_at: Time.current
    )
  end

  # The token is replaced too: left in place, the same token still on the org
  # page would verify the fleet again on its next check.
  def revoke_rsi_verification!
    update_columns(
      rsi_verified_at: nil,
      rsi_verified_sid: nil,
      rsi_verification_status: nil,
      rsi_verification_token: self.class.new_rsi_verification_token,
      updated_at: Time.current
    )

    FleetFidClaim.cancel_for_lost_verification!(self)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def self.valid_fid?(value)
    FID_FORMAT.match?(value.to_s)
  end

  # `X-1`, `X-2`, ...: an SID never contains a hyphen, so a suffixed FID can
  # never be one another fleet verifies and claims in turn.
  def self.next_free_fid(base)
    base = base.to_s.upcase
    taken = kept.where("normalized_fid LIKE ?", "#{sanitize_sql_like(base.downcase)}-%").pluck(:normalized_fid).to_set

    suffix = (1..).find { |n| taken.exclude?("#{base.downcase}-#{n}") }

    "#{base}-#{suffix}"
  end

  def rsi_verification_cooling_down?
    rsi_verification_checked_at.present? &&
      rsi_verification_checked_at > RSI_VERIFICATION_COOLDOWN.ago
  end

  # `fleet:manage` is the privilege that already means "runs this fleet".
  def managers
    fleet_memberships.kept.accepted.includes(:fleet_role, :user)
      .select { |membership| membership.has_access?(["fleet:manage"]) }
      .filter_map(&:user)
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

  def setup_default_squadron_roles!
    FleetSquadronRole.setup_defaults!(self)
  end

  # The role a new member gets. A fleet created while the flag was migrated in
  # may have none marked, and gets what new members always got before it.
  def default_member_role
    marked = fleet_roles.find_by(new_member_default: true)
    return marked if marked

    # Never the permanent Admin role, whatever sorts last.
    fallback = fleet_roles.ranked.where(permanent: [false, nil]).last
    return fallback if fallback

    setup_default_roles!
    fleet_roles.reload.find_by(new_member_default: true)
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
    fleet_memberships.kept.find_by(user_id:)&.invited?
  end

  def requested(user_id)
    fleet_memberships.kept.find_by(user_id:)&.requested?
  end

  def primary(user_id)
    fleet_memberships.kept.find_by(user_id:)&.primary
  end

  def ships_filter(user_id)
    fleet_memberships.kept.find_by(user_id:)&.ships_filter
  end

  def hangar_group_id(user_id)
    fleet_memberships.kept.find_by(user_id:)&.hangar_group_id
  end

  def accepted_at(user_id)
    fleet_memberships.kept.find_by(user_id:)&.accepted_at
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
    return @subscribed[date] if @subscribed&.key?(date)

    @subscribed ||= {}
    # An eager-loaded association answers without a query, which is what keeps a
    # list of fleets from issuing one apiece. `exists?` would ignore the loaded
    # records and go to the database anyway.
    @subscribed[date] = if fleet_subscriptions.loaded?
      fleet_subscriptions.any? { |subscription| subscription.active_on?(date) }
    else
      fleet_subscriptions.active_on(date).exists?
    end
  end

  # Called by FleetSubscription after a write, and by `reload`. The memo is a
  # per-request read rather than a cache with an invalidation story: a second
  # Fleet instance loaded elsewhere in the same request keeps its own answer.
  def clear_entitlement_cache
    @subscribed = nil
    @active_subscription = nil
  end

  def reload(*)
    clear_entitlement_cache
    super
  end

  # The row itself, for anything that needs to say *why* -- an admin screen, or
  # a notification naming what lapsed.
  def active_subscription(date = Date.current)
    return @active_subscription[date] if @active_subscription&.key?(date)

    @active_subscription ||= {}
    @active_subscription[date] = if fleet_subscriptions.loaded?
      fleet_subscriptions.find { |subscription| subscription.active_on?(date) }
    else
      fleet_subscriptions.active_on(date).first
    end
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

  # A member's flag says they are in the org the fleet named then. Kept across a
  # new SID, it would show them as members of an org they may not be in once
  # the fleet proves the new one.
  # The members' org lists answer for the new SID without asking RSI again.
  private def sync_membership_verification
    FleetMembershipVerification.sync_fleet(self)
  end

  # The last check time goes too: the cooldown is for asking RSI about one
  # org again, not about a new one, and a check still out for the old SID no
  # longer matches it.
  private def verified_rsi_sid_locked
    return if rsi_verified_at_was.blank? || rsi_verified_sid_was.blank?

    errors.add(:rsi_sid, :locked_while_verified)
  end

  # An FID with an open claim waits for its claimant: the holder may leave it,
  # but neither it nor anybody else may take it in the meantime. A holder only
  # changing the case of the FID it has is not taking it.
  private def fid_not_reserved
    return if fid.blank?
    return if fid_was.present? && fid_was.casecmp?(fid)
    return unless FleetFidClaim.reserved?(fid, except: self)

    errors.add(:fid, :reserved)
  end

  private def reset_rsi_verification
    self.rsi_verified_at = nil
    self.rsi_verified_sid = nil
    self.rsi_verification_status = nil
    self.rsi_verification_checked_at = nil
  end

  private def fid_not_a_route_name
    errors.add(:fid, :route_name) if RESERVED_SLUGS.include?(self.class.slug_for(fid.to_s))
  end

  private def secondary_activity_differs
    errors.add(:secondary_activity, :same_as_primary) if secondary_activity == primary_activity
  end

  private def update_slugs
    self.slug = generate_slug(fid)
  end

  private def preserve_payout_participant_names
    payout_participants.where(name: nil).update_all(name: name)
  end
end
