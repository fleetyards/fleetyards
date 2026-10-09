# frozen_string_literal: true

class FleetMembership < ApplicationRecord
  include AASM
  include Discard::Model

  attr_accessor :update_reason, :update_reason_description, :author_id

  # Joined as one of many at once, so neither the officers nor the members'
  # views are told about each: the sweep refreshes the views once at the end.
  attr_accessor :quiet

  AVAILABLE_PRIVILEGES = [
    "fleet:memberships:read",
    "fleet:memberships:create",
    "fleet:memberships:update",
    "fleet:memberships:delete",
    "fleet:memberships:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:memberships:manage"],
    member: ["fleet:memberships:read"]
  }.freeze

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS, meta: {
    author_id: :author_id,
    reason: :update_reason,
    reason_description: :update_reason_description
  }

  belongs_to :fleet, touch: true
  belongs_to :fleet_role, optional: true
  belongs_to :user, touch: true

  has_many :fleet_squadron_memberships, dependent: :destroy
  has_many :fleet_squadrons, through: :fleet_squadron_memberships
  has_many :fleet_squadron_requests, dependent: :destroy
  has_many :fleet_event_signups

  # A squadron membership can be added after this association was loaded, so
  # make the dependent destroy callback read the current rows before deleting
  # the fleet membership.
  before_destroy -> { association(:fleet_squadron_memberships).reset }, prepend: true

  paginates_per 30

  enum :ships_filter,
    {all: 0, hangar_group: 1, hide: 2},
    prefix: true

  # What this member lets the fleet see of the recipes they hold. Two positions
  # rather than three: there is nothing to group a marker by.
  enum :blueprints_filter,
    {all: 0, hide: 1},
    prefix: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "aasm_state", "accepted_at", "created_at", "declined_at", "fleet_id", "fleet_role_id", "hangar_group_id",
      "hide_ships", "id", "id_value", "invited_at", "invited_by", "name", "nickname", "primary", "requested_at",
      "blueprints_filter", "role", "squadron_slug", "squadron_membership_created_at",
      "ships_filter", "updated_at", "used_invite_token", "user_id", "username", "state"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["fleet", "fleet_role", "user", "fleet_squadrons", "fleet_squadron_memberships"]
  end

  validate_enum_attributes :ships_filter, :blueprints_filter

  validates :user_id, uniqueness: {scope: :fleet_id, conditions: -> { where(discarded_at: nil) }}

  validates :nickname, length: {maximum: 255}, allow_blank: true

  DEFAULT_SORTING_PARAMS = ["created_at desc", "accepted_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "rsiHandle asc", "rsiHandle desc", "username asc", "username desc",
    "createdAt asc", "createdAt desc", "acceptedAt asc", "acceptedAt desc",
    "lastActiveAt asc", "lastActiveAt desc"
  ]

  # When somebody joined, and at which rank, are questions about one squadron,
  # so only that squadron's roster can sort by them -- across the whole fleet
  # a member has no single answer, or none.
  SQUADRON_ROSTER_SORTING_PARAMS = [
    *ALLOWED_SORTING_PARAMS,
    "squadronMembershipCreatedAt asc", "squadronMembershipCreatedAt desc",
    "squadronRank asc", "squadronRank desc"
  ].freeze

  # Everything the member partial reads, so a roster renders in a fixed number
  # of queries rather than a handful per row.
  ROSTER_PRELOADS = [
    :fleet,
    :fleet_role,
    {user: [{current_location: :parent}, :omniauth_connections, {avatar_attachment: :blob}]},
    {fleet_squadron_memberships: [:fleet_squadron_role, {fleet_squadron: {icon_attachment: :blob}}]}
  ].freeze

  ransack_alias :username, :user_username
  ransack_alias :rsi_handle, :user_rsi_handle
  ransack_alias :last_active_at, :user_last_active_at
  ransack_alias :name, :user_username
  # The slug, not the name: a fleet renames its roles, and a saved filter or a
  # shared link must keep meaning the same role.
  ransack_alias :role, :fleet_role_slug
  ransack_alias :squadron_slug, :fleet_squadrons_slug
  ransack_alias :squadron_membership_created_at, :fleet_squadron_memberships_created_at
  ransack_alias :state, :aasm_state

  before_validation :set_default_ships_filter
  before_validation :set_default_blueprints_filter
  before_validation :normalize_nickname
  # From the user's stored org list, so a member whose list already names the
  # fleet's SID is verified the moment they join, without asking RSI.
  before_create -> { self.verified = FleetMembershipVerification.verified?(user, fleet) if user && fleet }
  # A rank an officer gave is their choice, so the role no longer ends it.
  before_update -> { self.discord_role_granted = false }, if: -> { discord_role_granted? && fleet_role_id_changed? }
  after_create :broadcast_create, unless: :quiet
  after_destroy :broadcast_destroy, :remove_fleet_vehicles
  after_save :set_primary
  after_create_commit :schedule_setup_fleet_vehicles
  after_update_commit :schedule_update_fleet_vehicles
  after_commit :broadcast_update, unless: :quiet
  after_commit :sync_discord_roles, on: %i[create update], if: :discord_roles_affected?
  after_commit :refresh_discord_join_request, if: :join_request_closed?
  before_destroy :check_if_can_be_destroyed
  before_discard :check_if_can_be_destroyed
  after_discard :broadcast_destroy, :remove_fleet_vehicles, :withdraw_upcoming_event_signups, :sync_discord_roles
  after_undiscard :broadcast_create, :schedule_setup_fleet_vehicles, :sync_discord_roles

  # The uniqueness validation reads before the insert, so two joins arriving
  # together both pass it and the partial unique index rejects the loser. Give
  # the loser the validation error the sequential case already gets, rather
  # than a RecordNotUnique that reaches the client as a 500.
  #
  # The savepoint is what lets a caller wrap this in a transaction of its own:
  # the violation aborts whichever transaction it happens in, so without one
  # the rescue would hand back a connection whose next statement fails.
  def save_without_conflict
    self.class.transaction(requires_new: true) { save }
  rescue ActiveRecord::RecordNotUnique
    errors.add(:user_id, :taken)
    false
  end

  # The member's org list, from Citizen iD or their RSI organisations page,
  # names the SID the fleet gives. That only says something about the fleet once
  # the fleet has proved the SID is its own; until then anyone could have typed
  # it.
  def rsi_verified?
    verified? && fleet.rsi_verified?
  end

  def has_access?(privileges)
    return false if fleet_role.blank?

    fleet_role.has_access?(privileges)
  end

  # Named UI capabilities derived from the same privilege lists the fleet
  # policies authorize against, so the client gates on evaluated booleans
  # instead of re-checking privilege sets. Kept in sync with the policies by
  # FleetMembershipCapabilitiesTest.
  CAPABILITY_PRIVILEGES = {
    read_members: ["fleet:manage", "fleet:memberships:manage", "fleet:memberships:read"],
    create_members: ["fleet:manage", "fleet:memberships:manage", "fleet:memberships:create"],
    update_members: ["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"],
    destroy_members: ["fleet:manage", "fleet:memberships:manage", "fleet:memberships:destroy"],
    read_squadrons: ["fleet:manage", "fleet:squadrons:manage", "fleet:squadrons:read"],
    create_squadrons: ["fleet:manage", "fleet:squadrons:manage", "fleet:squadrons:create"],
    update_squadrons: ["fleet:manage", "fleet:squadrons:manage", "fleet:squadrons:update"],
    destroy_squadrons: ["fleet:manage", "fleet:squadrons:manage", "fleet:squadrons:delete"],
    manage_squadron_members: ["fleet:manage", "fleet:squadrons:manage", "fleet:squadrons:members:manage"],
    manage_squadrons: ["fleet:manage", "fleet:squadrons:manage"],
    enable_squadrons: ["fleet:manage", "fleet:update"],
    read_invites: ["fleet:manage", "fleet:invites:manage", "fleet:invites:read"],
    create_invites: ["fleet:manage", "fleet:invites:manage", "fleet:invites:create"],
    destroy_invites: ["fleet:manage", "fleet:invites:manage", "fleet:invites:delete"],
    read_inventories: ["fleet:manage", "fleet:inventories:manage", "fleet:inventories:read"],
    create_inventories: ["fleet:manage", "fleet:inventories:manage", "fleet:inventories:create"],
    update_inventories: ["fleet:manage", "fleet:inventories:manage", "fleet:inventories:update"],
    destroy_inventories: ["fleet:manage", "fleet:inventories:manage", "fleet:inventories:delete"],
    read_allies: ["fleet:manage", "fleet:allies:manage", "fleet:allies:read"],
    create_allies: ["fleet:manage", "fleet:allies:manage", "fleet:allies:create"],
    destroy_allies: ["fleet:manage", "fleet:allies:manage", "fleet:allies:delete"],
    manage_allies: ["fleet:manage", "fleet:allies:manage"],
    read_vehicles: ["fleet:manage", "fleet:vehicles:manage", "fleet:vehicles:read"],
    read_blueprints: ["fleet:manage", "fleet:blueprints:read"],
    read_events: ["fleet:manage", "fleet:events:manage", "fleet:events:read"],
    read_contracts: ["fleet:manage", "fleet:contracts:manage", "fleet:contracts:read"],
    read_roles: ["fleet:manage", "fleet:roles:manage", "fleet:roles:read"],
    update_roles: ["fleet:manage", "fleet:roles:manage", "fleet:roles:update"],
    manage_fleet: ["fleet:manage"],
    update_fleet: ["fleet:manage", "fleet:update", "fleet:update:description", "fleet:update:images"],
    destroy_fleet: ["fleet:manage", "fleet:delete"]
  }.freeze

  def capabilities
    CAPABILITY_PRIVILEGES.transform_values { |privileges| has_access?(privileges) }
  end

  def check_if_can_be_destroyed
    return unless fleet_role&.permanent?

    errors.add(:base, I18n.t("activerecord.errors.models.fleet_membership.attributes.base.cannot_destroy_from_permanent_role"))
    throw(:abort)
  end

  aasm timestamps: true, whiny_transitions: false do
    state :created, initial: true
    state :invited
    state :requested
    state :accepted
    state :declined

    event :invite, after_commit: :notify_invited_user do
      transitions from: :created, to: :invited
    end

    event :request, after_commit: %i[notify_fleet_admins post_discord_join_request] do
      transitions from: :created, to: :requested
    end

    event :accept_invitation, after_commit: :on_accept_invitation do
      transitions from: :invited, to: :accepted
    end

    event :accept_request, after_commit: :on_accept_request do
      transitions from: :requested, to: :accepted
    end

    # Holding the fleet's join role in its Discord server: the server vetted
    # the player already, so nobody answers a request.
    event :join, after_commit: :on_join do
      transitions from: :created, to: :accepted
    end

    event :decline do
      transitions from: %i[invited requested], to: :declined
    end
  end

  def set_default_ships_filter
    return if ships_filter.present?

    self.ships_filter = "all"
  end

  def set_default_blueprints_filter
    return if blueprints_filter.present?

    self.blueprints_filter = "all"
  end

  def normalize_nickname
    return if nickname.nil?

    self.nickname = nickname.strip.presence
  end

  def schedule_setup_fleet_vehicles
    Updater::FleetMembershipVehiclesSetupJob.perform_async(id)
  end

  def schedule_update_fleet_vehicles
    return if discarded? || saved_change_to_discarded_at?

    Updater::FleetMembershipVehiclesUpdateJob.perform_async(id)
  end

  def setup_fleet_vehicles
    return unless accepted?
    return if ships_filter_hide?

    user.vehicles.visible.each do |vehicle|
      update_fleet_vehicle(vehicle)
    end
  end

  def update_fleet_vehicles
    return unless accepted?

    if ships_filter_hide?
      remove_fleet_vehicles
    else
      user.vehicles.visible.each do |vehicle|
        update_fleet_vehicle(vehicle)
      end
    end
  end

  def remove_fleet_vehicles
    FleetVehicle.where(fleet_id:, vehicle_id: user.vehicle_ids).destroy_all
  end

  # A discarded membership keeps its signups, so a seat it held would stay
  # taken. Events already under way keep theirs as the record of who flew, and a
  # restored membership does not get its seats back: they may be gone.
  def withdraw_upcoming_event_signups
    fleet_event_signups
      .where.not(status: "withdrawn")
      .joins(:fleet_event)
      .where.not(fleet_events: {status: %w[completed cancelled]})
      .where(
        "(fleet_events.recurring AND (fleet_event_signups.occurrence_date IS NULL OR fleet_event_signups.occurrence_date >= :today)) OR " \
        "(NOT fleet_events.recurring AND fleet_events.status != 'active' AND fleet_events.starts_at > :now)",
        today: Date.current, now: Time.current
      )
      .includes(:fleet_event)
      # Each withdrawal touches its event, so two removals at once must touch
      # them in the same order or they deadlock.
      .order(:fleet_event_id, :id)
      .each do |signup|
        next if signup.occurrence_started?

        # A legacy row failing a later validation must not block the removal.
        signup.withdraw!(validate: false)
        ActiveRecord.after_all_transactions_commit do
          ActiveSupport::Notifications.instrument("fleet_event_signup.withdrawn", signup:)
        end
      end
  end

  def update_fleet_vehicle(vehicle)
    case ships_filter
    when "all"
      update_fleet_vehicle_for_all(vehicle)
    when "hangar_group"
      update_fleet_vehicle_for_hangar_group(vehicle)
    else
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    end
  end

  def update_fleet_vehicle_for_all(vehicle)
    if vehicle.wanted?
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    else
      FleetVehicle.find_or_create_by(fleet_id:, vehicle_id: vehicle.id)
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def update_fleet_vehicle_for_hangar_group(vehicle)
    parent_vehicle = Vehicle.find_by(id: vehicle.vehicle_id) if vehicle.loaner?
    hangar_group_ids = (vehicle.hangar_group_ids + (parent_vehicle&.hangar_group_ids || []))

    if hangar_group_ids.include?(hangar_group_id)
      FleetVehicle.find_or_create_by(fleet_id:, vehicle_id: vehicle.id)
    else
      FleetVehicle.find_by(fleet_id:, vehicle_id: vehicle.id)&.destroy
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def set_primary
    return if discarded?
    return unless primary?

    FleetMembership.kept.where(user_id:, primary: true)
      .where.not(id:)
      .update_all(primary: false)
  end

  def notify_invited_user
    return unless invited?
    return if user.email.blank?

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :fleet_invite,
        title: I18n.t("notifications.fleet_invite.title", fleet: fleet.name),
        link: Rails.application.routes.url_helpers.frontend_fleets_invites_path,
        record: self
      )
    end
  end

  def on_accept_invitation
    return if quiet

    notify_fleet_admins
    broadcast_to_members
  end

  def notify_fleet_admins
    return unless requested? || accepted?

    admin_users = fleet.fleet_memberships.kept.accepted.includes(:fleet_role, :user).select { |m|
      m.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
    }.filter_map { |m| m.user if m.user.email.present? }

    return if admin_users.blank?

    type = requested? ? :fleet_member_requested : :fleet_member_accepted

    admin_users.each do |admin_user|
      I18n.with_locale(admin_user.notification_locale) do
        Notification.notify!(
          user: admin_user,
          type:,
          title: I18n.t("notifications.#{type}.title", username: user.username, fleet: fleet.name),
          link: Rails.application.routes.url_helpers.frontend_fleet_members_path(fleet.slug),
          record: self
        )
      end
    end
  end

  # Answers a join request under a row lock and returns :done, :not_pending or
  # :failed. Every path that accepts or declines one goes through here: two
  # officers answering at once each hold a copy that still reads `requested`,
  # and with whiny_transitions off both transitions would save -- a request
  # could end up declined after its applicant was told they were accepted.
  def answer_request(accept:, author_id: nil)
    with_lock do
      # Withdrawing discards the membership and leaves its state alone.
      next :not_pending unless kept? && requested?

      self.author_id = author_id if author_id.present?
      if accept ? accept_request! : decline!
        :done
      else
        :failed
      end
    end
  end

  # What a player asking to join gets: a request, unless they hold the fleet's
  # join role in its Discord server.
  def request_or_join!
    ::Discord::JoinRole.new(fleet).request_or_join(self)
  end

  def on_join
    notify_joined_by_discord_role
    return if quiet

    notify_fleet_admins
    broadcast_to_members
  end

  def post_discord_join_request
    return if ::Discord::EventAnnouncement.officers_targets(fleet).empty?

    ::Discord::PostJoinRequestJob.perform_async(id)
  end

  # Answered, withdrawn or removed while it was pending.
  def join_request_closed?
    return requested? if destroyed?

    saved_change_to_aasm_state?(from: "requested") || (saved_change_to_discarded_at? && discarded? && requested?)
  end

  def refresh_discord_join_request
    ::Discord::RefreshJoinRequestMessageJob.perform_async(id, discord_request_channel_id, discord_request_message_id)
  end

  def on_accept_request
    notify_new_member
    broadcast_to_members unless quiet
  end

  def broadcast_to_members
    payload = to_jbuilder_hash
    fleet.fleet_memberships.kept.includes(:user).find_each do |member|
      FleetVehiclesChannel.broadcast_to(member.user, payload)
    end
  end

  # Everything a quiet sweep's admissions left out of the members' views,
  # once for all of them.
  def broadcast_sweep_refresh
    payload = to_jbuilder_hash
    each_fleet_recipient do |user|
      FleetMembersChannel.broadcast_to(user, payload)
      FleetVehiclesChannel.broadcast_to(user, payload)
    end
  end

  def notify_new_member
    return unless accepted?
    return if user.email.blank?

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :fleet_request_accepted,
        title: I18n.t("notifications.fleet_request_accepted.title", fleet: fleet.name),
        link: Rails.application.routes.url_helpers.frontend_fleets_invites_path,
        record: self
      )
    end
  end

  # The role is the only way in that skips a request, so this player never
  # asked: they are told why they are a member.
  def notify_joined_by_discord_role
    return if user.email.blank?

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :fleet_joined_by_discord_role,
        title: I18n.t("notifications.fleet_joined_by_discord_role.title", fleet: fleet.name),
        link: Rails.application.routes.url_helpers.frontend_fleet_path(slug: fleet.slug),
        record: self
      )
    end
  end

  # Only the two things that change which Discord roles a member should hold:
  # whether they are an accepted member at all, and which rank they hold.
  # Everything else about a membership -- ship filters, hangar groups, a primary
  # flag -- has no bearing on it, and enqueuing on every save would put a
  # Discord round trip behind ordinary edits.
  def discord_roles_affected?
    saved_change_to_aasm_state? || saved_change_to_fleet_role_id?
  end

  def sync_discord_roles
    return unless ::Discord::ApiClient.configured?
    return if fleet&.fleet_notification_setting&.discord_guild_id.blank?

    ::Discord::SyncMemberRolesJob.perform_async(id)
  end

  def broadcast_update
    return if saved_change_to_discarded_at?

    payload = to_jbuilder_hash

    each_fleet_recipient do |user|
      FleetMembersChannel.broadcast_to(user, payload)
      FleetVehiclesChannel.broadcast_to(user, payload) if ships_filter_changed?
    end
  end

  def broadcast_create
    payload = to_jbuilder_hash

    each_fleet_recipient { |user| FleetMembersChannel.broadcast_to(user, payload) }
  end

  def broadcast_destroy
    payload = to_jbuilder_hash

    each_fleet_recipient do |user|
      FleetMembersChannel.broadcast_to(user, payload)
      FleetVehiclesChannel.broadcast_to(user, payload)
    end
  end

  # The users in one query rather than one per member: every squadron join or
  # rank change touches the membership and lands here, so a lookup per member
  # made those writes scale with the size of the fleet.
  private def each_fleet_recipient(&)
    User.where(id: fleet.fleet_memberships.kept.select(:user_id)).find_each(&)
  end

  # The ordinary squadron this member already holds, if any. A member holds at
  # most one; teams sit outside the rule and never count.
  def exclusive_squadron(except: nil)
    FleetSquadron
      .joins(:fleet_squadron_memberships)
      .where(fleet_id:, team: false)
      .where(fleet_squadron_memberships: {fleet_membership_id: id})
      .where.not(id: except&.id)
      .first
  end

  # The squadron this member is waiting to hear back from, if any. A member
  # asks one squadron at a time.
  def requested_squadron(except: nil)
    FleetSquadron
      .joins(:fleet_squadron_requests)
      .where(fleet_squadron_requests: {fleet_membership_id: id})
      .where.not(id: except&.id)
      .order("fleet_squadron_requests.created_at")
      .first
  end

  def promote
    return if next_fleet_role == fleet_role || next_fleet_role.nil?

    update(fleet_role: next_fleet_role)
  end

  def demote
    return if fleet_role.permanent? && fleet_role.fleet_memberships.kept.count == 1
    return if prev_fleet_role == fleet_role || prev_fleet_role.nil?

    update(fleet_role: prev_fleet_role)
  end

  def next_fleet_role
    ranked_roles, index = ranked_roles_and_index
    return if index.nil? || index - 1 < 0

    ranked_roles[index - 1]
  end

  def prev_fleet_role
    ranked_roles, index = ranked_roles_and_index
    return if index.nil?

    ranked_roles[index + 1]
  end

  private def ranked_roles_and_index
    return [nil, nil] if fleet_role.nil?

    ranked_roles = fleet.fleet_roles.ranked.to_a

    [ranked_roles, ranked_roles.index(fleet_role)]
  end
end
