# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                        :uuid             not null, primary key
#  calendar_feed_token       :string
#  claim_key                 :string
#  confirmation_sent_at      :datetime
#  confirmation_token        :string(255)
#  confirmed_at              :datetime
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  current_system            :string
#  current_system_code       :string
#  date_format               :string           default("dmy_dots"), not null
#  discord                   :string
#  email                     :string(255)      default(""), not null
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  encrypted_password        :string(255)      default(""), not null
#  failed_attempts           :integer          default(0), not null
#  friends_hangar            :boolean          default(FALSE), not null
#  friends_hangar_stats      :boolean          default(FALSE), not null
#  friends_wishlist          :boolean          default(FALSE), not null
#  guilded                   :string
#  hangar_updated_at         :datetime
#  hide_owner                :boolean          default(FALSE), not null
#  homepage                  :string
#  inventory_transfer_policy :integer          default("everyone"), not null
#  last_active_at            :datetime
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  latitude                  :decimal(10, 6)
#  locale                    :string(255)
#  location                  :string
#  locked_at                 :datetime
#  longitude                 :decimal(10, 6)
#  normalized_email          :string
#  normalized_username       :string
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  otp_secret                :string
#  password_set_manually     :boolean          default(FALSE), not null
#  public_hangar             :boolean          default(TRUE)
#  public_hangar_loaners     :boolean          default(FALSE)
#  public_hangar_stats       :boolean          default(FALSE)
#  public_wishlist           :boolean          default(FALSE)
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  rsi_handle_verified       :boolean          default(FALSE), not null
#  sale_notify               :boolean          default(FALSE)
#  show_online_status        :boolean          default(TRUE), not null
#  sign_in_count             :integer          default(0), not null
#  tester                    :boolean          default(FALSE)
#  tracking                  :boolean          default(TRUE)
#  transfers_blocked_at      :datetime
#  transfers_blocked_reason  :text
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#  supported_fleet_id        :uuid
#
# Indexes
#
#  index_users_on_calendar_feed_token    (calendar_feed_token) UNIQUE
#  index_users_on_claim_key              (claim_key) UNIQUE WHERE (claim_key IS NOT NULL)
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_email                  (email) UNIQUE
#  index_users_on_id_where_not_tracking  (id) WHERE (tracking = false)
#  index_users_on_last_active_at         (last_active_at)
#  index_users_on_lower_email            (lower((email)::text))
#  index_users_on_lower_username         (lower((username)::text))
#  index_users_on_normalized_email       (normalized_email)
#  index_users_on_normalized_username    (normalized_username)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_supported_fleet_id     (supported_fleet_id) WHERE (supported_fleet_id IS NOT NULL)
#  index_users_on_unlock_token           (unlock_token) UNIQUE
#  index_users_on_username               (username) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (supported_fleet_id => fleets.id) ON DELETE => nullify
#
class User < ApplicationRecord
  # A version of a user row holds their old email and username verbatim, so it
  # has to go when the account does.
  include ErasableVersionsConcern

  # Both columns were only ever written by the migration that added them -- the
  # `counter_cache: true` meant to maintain them sat on the `has_many` side,
  # where it does nothing. They are ignored here a release ahead of the
  # migration that drops them: the pre-deploy hook migrates before any new
  # container boots, so the release still serving traffic must already have
  # stopped selecting them.
  self.ignored_columns += %w[purchased_vehicles_count wanted_vehicles_count]

  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a change a user makes to their own
  # account files nothing -- this records what an admin did to somebody else's.
  #
  # `unconfirmed_email` is in the list because devise is `reconfirmable`: an
  # admin changing a confirmed user's address writes there and leaves `email`
  # alone until the user confirms, so versioning `email` by itself would record
  # the change nowhere. `email` still covers an account that was never confirmed,
  # where devise writes it directly.
  has_paper_trail on: %i[update],
    only: %i[
      username email unconfirmed_email rsi_handle sale_notify public_hangar
      public_hangar_loaners public_wishlist hide_owner tester
      friends_hangar friends_hangar_stats friends_wishlist show_online_status
    ],
    if: ->(record) { record.author_id.present? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  include UrlFieldConcern
  include ActiveStorageVariants
  include InventoryTransferParty
  include Rails.application.routes.url_helpers

  geocoded_by :location
  after_validation :geocode, if: :will_save_change_to_location?
  before_validation :clear_coordinates, if: -> { will_save_change_to_location? && location.blank? }
  before_validation :match_current_system, if: :will_save_change_to_current_system?

  devise :two_factor_authenticatable, :two_factor_backupable, :recoverable, :trackable,
    :validatable, :confirmable, :rememberable, :timeoutable, :omniauthable,
    omniauth_providers: [:discord, :twitch, :google, :github, :bluesky, :citizenid, :patreon],
    authentication_keys: [:login], otp_secret_encryption_key: Rails.application.credentials.devise_otp_secret!,
    otp_backup_code_length: 10, otp_number_of_backup_codes: 10

  before_destroy :check_fleet_memberships
  before_destroy :preserve_payout_participant_names, prepend: true

  has_many :vehicles, dependent: :destroy
  has_many :purchased_vehicles,
    -> { where(wanted: false) },
    class_name: "Vehicle",
    inverse_of: false
  has_many :wanted_vehicles,
    -> { where(wanted: true) },
    class_name: "Vehicle",
    inverse_of: false
  has_many :models,
    through: :vehicles
  has_many :vehicle_modules,
    through: :vehicles
  has_many :vehicle_upgrades,
    through: :vehicles
  has_many :manufacturers,
    through: :models
  has_many :public_vehicles,
    -> { where(wanted: false, public: true) },
    dependent: :destroy,
    class_name: "Vehicle",
    inverse_of: false
  has_many :public_models,
    class_name: "Model",
    through: :public_vehicles,
    source: :model,
    inverse_of: false
  has_many :fleet_memberships,
    -> { order(primary: :desc) },
    dependent: :destroy,
    inverse_of: false
  has_many :kept_fleet_memberships,
    -> { kept.order(primary: :desc) },
    class_name: "FleetMembership",
    inverse_of: false
  has_many :fleets,
    -> { kept },
    through: :kept_fleet_memberships

  # The fleet this person's donations support, answerable before any donation
  # exists. Supporters::Linker stamps it onto a contribution the moment one is
  # matched to this account; the contribution keeps the authoritative answer
  # from then on, so changing this later does not rewrite past donations.
  belongs_to :supported_fleet, class_name: "Fleet", optional: true

  has_many :inventories, as: :holder, dependent: :destroy

  # The crafting recipes this person holds. Personal like a hangar, and reaching
  # a fleet only through the membership that says it may -- see
  # `FleetMembership#blueprints_filter`.
  has_many :user_blueprints, dependent: :destroy
  has_many :blueprints, through: :user_blueprints

  has_many :fleet_contract_assignments, dependent: :destroy
  has_many :fleet_contracts, through: :fleet_contract_assignments

  # Both directions of the same table, because a friendship is one row per
  # unordered pair -- see `PartyRelationship`. Nothing outside the inbox should
  # use either of these; `#friends` and `#friend_of?` read over both columns.
  has_many :sent_friend_requests,
    class_name: "Friendship",
    foreign_key: :requester_id,
    dependent: :destroy,
    inverse_of: :requester
  has_many :received_friend_requests,
    class_name: "Friendship",
    foreign_key: :addressee_id,
    dependent: :destroy,
    inverse_of: :addressee

  has_many :notifications, dependent: :delete_all
  has_many :notification_preferences, dependent: :delete_all

  has_many :oauth_applications, class_name: "Oauth::Application", as: :owner
  has_many :omniauth_connections, dependent: :destroy

  # Nullify, never destroy: a deleted account must not erase the bookkeeping for
  # money that was actually received.
  has_many :supporter_contributions, dependent: :nullify

  # Every one of these is an unqualified FK to users, so without a dependent
  # rule deleting an account raises InvalidForeignKey rather than going
  # through. check_fleet_memberships does not cover them -- a tour needs no
  # fleet at all.
  has_many :tours, foreign_key: :created_by_id, inverse_of: :created_by, dependent: :destroy
  has_many :payout_participants, dependent: :nullify
  has_many :added_payout_participants,
    class_name: "PayoutParticipant",
    foreign_key: :added_by_id,
    inverse_of: :added_by,
    dependent: :nullify
  has_many :recorded_payout_entries,
    class_name: "PayoutEntry",
    foreign_key: :recorded_by_id,
    inverse_of: :recorded_by,
    dependent: :nullify
  has_many :settled_payout_ledgers,
    class_name: "PayoutLedger",
    foreign_key: :settled_by_id,
    inverse_of: :settled_by,
    dependent: :nullify
  has_many :confirmed_payout_transfers,
    class_name: "PayoutTransfer",
    foreign_key: :confirmed_by_id,
    inverse_of: :confirmed_by,
    dependent: :nullify

  has_many :access_grants,
    class_name: "Oauth::AccessGrant",
    foreign_key: :resource_owner_id,
    dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens,
    class_name: "Oauth::AccessToken",
    foreign_key: :resource_owner_id,
    dependent: :delete_all # or :destroy if you need callbacks

  # Legacy Validation for exisiting short usernames
  validates :username,
    uniqueness: {case_sensitive: false},
    presence: true,
    format: {with: /\A[a-zA-Z0-9\-_]+\Z/},
    on: :update

  validates :username,
    uniqueness: {case_sensitive: false},
    length: {minimum: 3},
    presence: true,
    format: {with: /\A[a-zA-Z0-9\-_]{3,}\Z/},
    on: :create

  validates :email,
    uniqueness: {case_sensitive: false},
    presence: true

  attr_accessor :login

  before_validation :clean_username
  before_validation :set_normalized_login_fields
  before_validation :update_urls
  before_create :setup_otp_secret
  after_create :create_default_notification_preferences

  # Keyed on the columns rather than on Devise's after_confirmation hook, so an
  # account confirmed by assignment -- an OAuth signup, an admin, a backfill --
  # is covered as well as one that went through `confirm`.
  #
  # Reconfirmation changes both, so confirmed_at alone would be enough for it.
  # The email arm is for the case that changes only that: an admin moving an
  # account with skip_reconfirmation!.
  after_commit :link_supporter_contributions,
    if: -> {
      confirmed_at.present? &&
        (saved_change_to_confirmed_at? || saved_change_to_email?)
    }

  after_update :notify_user
  after_update :sync_sale_notify_preference
  after_save :touch_fleet_memberships

  # Turning the switch off has to reach the rosters already showing the dot, and
  # turning it back on has to bring it back — neither is a connection change, so
  # nothing else would broadcast it. Only worth sending while there is something
  # to correct.
  after_commit :broadcast_online_status_change,
    if: -> { saved_change_to_show_online_status? && ::UserPresence.online?(id) }

  has_one_attached :avatar
  validates :avatar, no_vector_image: true

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = [
    "username asc", "username desc", "email asc", "email desc", "createdAt asc", "createdAt desc",
    "confirmedAt asc", "confirmedAt desc", "lastActiveAt asc", "lastActiveAt desc",
    "lastSignInAt asc", "lastSignInAt desc"
  ]

  ransack_alias :search, :username_or_email

  def self.ransackable_attributes(auth_object = nil)
    [
      "confirmed_at", "created_at", "current_sign_in_at", "discord", "email",
      "guilded", "hangar_updated_at", "homepage", "last_active_at", "last_sign_in_at", "locale",
      "id", "rsi_handle", "twitch", "updated_at", "username", "youtube",
      "search"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "fleet_memberships", "fleets", "manufacturers", "models", "public_models", "public_vehicles",
      "purchased_vehicles", "supporter_contributions", "vehicle_modules", "vehicle_upgrades",
      "vehicles", "wanted_vehicles"
    ]
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login.present?
      where(conditions.to_h)
        .find_by(["normalized_username = :value OR normalized_email = :value", {value: login.downcase}])
    elsif conditions.key?(:username) || conditions.key?(:email)
      find_by(conditions.to_h)
    end
  end

  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
    user&.valid_password?(password) ? user : nil
  end

  def self.confirmed
    where.not(confirmed_at: nil)
  end

  def self.unconfirmed
    where(confirmed_at: nil)
  end

  # Devise counts a sign-in on every authentication that is not a session fetch,
  # and with `remember_for` at six months against a two-hour session timeout,
  # most of those are the cookie proving who someone is again rather than anyone
  # signing in. Over one reporting window that was 433,159 writes to the busiest
  # table in the database, while the query that looks an account up by login ran
  # 27,858 times -- so about one in sixteen of them followed a password.
  #
  # Skipping the rest leaves `sign_in_count` counting what its name says, and
  # `last_sign_in_at` holding the last time someone really signed in. Nothing
  # loses "when was this account last used" -- that is `last_active_at`, which
  # every API client updates.
  def update_tracked_fields!(request)
    return if remembered_authentication?(request)

    super
  end

  private def remembered_authentication?(request)
    warden = request.env["warden"]
    return false if warden.nil?

    warden.winning_strategy.is_a?(Devise::Strategies::Rememberable)
  end

  # Everyone this user has an accepted friendship with, as a relation over a
  # subquery rather than an array of ids -- the bulk visibility filters compose
  # it into their own queries.
  # Whose hangar a given reader may see, as a scope rather than a predicate --
  # the multi-hangar embed asks it of a list of usernames at once, and asking
  # per user would be a query each. Mirrors `Public::UserPolicy#show?`, which is
  # what every single-user path goes through.
  scope :with_hangar_readable_by, ->(reader) {
    readable = where(public_hangar: true)
    next readable if reader.blank?

    readable.or(where(friends_hangar: true, id: ::Friendship.partner_ids_for(reader)))
  }

  # A Flipper feature read as a scope rather than as a predicate. The transfer
  # pickers are searched and paginated in SQL, so asking `Flipper.enabled?` per
  # row would filter one page at a time and leave the pagination header counting
  # rows it did not return.
  #
  # Only the gates that can be written as a query are read: the boolean, the
  # actor list, and the `testers` group, which is a column. The `admins` group
  # never matches a `User` at all. Neither percentage rollout can be expressed --
  # one picks a fraction of actors, the other answers differently per call for
  # the same actor -- and both admit everybody rather than nobody: offering
  # somebody `TransferGate` may still refuse is the harmless way round, and
  # hiding somebody who can in fact receive is not.
  scope :with_feature, ->(name) {
    gates = Flipper.feature(name).gate_values

    next all if gates.boolean
    next all if gates.percentage_of_actors.to_i.positive?
    next all if gates.percentage_of_time.to_i.positive?

    actor_ids = gates.actors.filter_map do |value|
      value.delete_prefix("User;") if value.start_with?("User;")
    end

    scoped = where(id: actor_ids)
    scoped = scoped.or(where(tester: true)) if gates.groups.include?("testers")
    scoped
  }

  # Who a transfer may be addressed to, which is the question
  # `Inventories::TransferGate` asks of a user recipient -- both flags, because
  # a transfer to a person lands in their own hangar inventory and they need the
  # surface as well as the feature. Kept as one scope so the picker and the
  # refusal cannot drift apart.
  scope :receiving_transfers, -> {
    where(id: with_feature(:inventory_transfers).select(:id))
      .where(id: with_feature(:hangar_inventories).select(:id))
  }

  def friends
    ::User.where(id: ::Friendship.partner_ids_for(self))
  end

  def friend_of?(other)
    ::Friendship.accepted_between?(self, other)
  end

  def friendship_with(other)
    ::Friendship.between(self, other)
  end

  def set_normalized_login_fields
    self.normalized_email = email.downcase
    self.normalized_username = username.downcase
  end

  def update_urls(force: false)
    %i[discord twitch youtube homepage guilded].each do |field|
      send(:"#{field}=", ensure_valid_url(self, field, force:))
    end
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  def public_hangar_url
    return short_public_hangar_url(username:) if Rails.configuration.app.short_domain.present?

    frontend_public_hangar_url(username:)
  end

  def citizenid_profile_url
    return unless rsi_handle_verified?

    connection = connection_for("citizenid")
    return if connection.blank?

    "#{Rails.configuration.app.citizenid[:issuer]}profile/#{connection.uid}"
  end

  def discord_profile_url
    connection = connection_for("discord")
    return if connection.blank?

    "https://discord.com/users/#{connection.uid}"
  end

  # detect rather than find_by: a user has at most a handful of connections, so
  # reading them from a preloaded association costs one query for all providers
  # instead of one per profile url - the fleet vehicle list asks every owner for
  # two of them.
  DATE_FORMATS = {
    "dmy_dots" => "dd.MM.yyyy",
    "dmy_slash" => "dd/MM/yyyy",
    "mdy_slash" => "MM/dd/yyyy",
    "ymd_dash" => "yyyy-MM-dd"
  }.freeze

  validates :date_format, inclusion: {in: DATE_FORMATS.keys}
  validate :supported_fleet_is_one_of_mine

  def discord_uid
    connection_for("discord")&.uid
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

  private def connection_for(provider)
    omniauth_connections.detect { |connection| connection.provider == provider }
  end

  def public_wishlist_url
    return short_public_wishlist_url(username:) if Rails.configuration.app.short_domain.present?

    frontend_public_wishlist_url(username:)
  end

  def resend_confirmation
    return if confirmed?

    return if confirmation_sent_at.present? && confirmation_sent_at > 10.minutes.ago

    send_confirmation_instructions
  end

  def clean_username
    return if username.blank?

    self.username = username.strip
  end

  def oauth_only?
    !password_set_manually && omniauth_connections.any?
  end

  def placeholder_email?
    email.ends_with?("@users.noreply.fleetyards.net")
  end

  # The band this month's spend falls in: 1 from a euro, 2 from six, 3 from
  # twenty-six. Each has an insignia of its own.
  #
  # Thresholds are compared against amount_cents, which every importer has
  # already normalised to EUR -- the figure the platforms report is whatever
  # currency the donor paid in, and comparing those directly would make a tier
  # mean different things to different people.
  #
  # Whole euros, so anything between two bands stays in the lower one: five
  # euros fifty has not reached the six the second band asks for.
  SUPPORTER_TIERS = {1 => 100, 2 => 600, 3 => 2600}.freeze

  # Perks and the public badge both, and deliberately blind to anonymity.
  # Anonymity says whether a contribution is *named* on the supporters page --
  # SupporterContribution#public_name is where it is answered -- not whether the
  # person behind it may be known to support at all.
  # Loaded once because all three answers below are drawn from the same rows,
  # and the admin user list renders them thirty to a page: separate queries per
  # answer made that ninety round trips on a cold fragment cache.
  #
  # Safe to hold for the life of the instance: a contribution touches its user
  # when it changes, so the next request builds a new one.
  def active_supporter_contributions
    @active_supporter_contributions ||= begin
      today = Date.current

      # A caller rendering a list preloads the association -- the admin user
      # index does -- and filtering what is already in memory is what keeps
      # that one query rather than one per row.
      if supporter_contributions.loaded?
        supporter_contributions.select do |contribution|
          contribution.active_in?(today.beginning_of_month, today.end_of_month)
        end
      else
        supporter_contributions.active_now(today).to_a
      end
    end
  end

  # `reload` clears the association cache but not a plain ivar, so without this
  # a reloaded record keeps answering from the rows it read before.
  def reload(*)
    @active_supporter_contributions = nil

    super
  end

  def supporter?
    active_supporter_contributions.any?
  end

  # 0 for everybody else, so callers can compare rather than branch on nil.
  #
  # Derived, never stored: it is a fact about this month's contributions and
  # would otherwise need recalculating every time one is added, edited, ended
  # or linked -- with nothing to notice when a recalculation was missed.
  def supporter_tier
    total = active_supporter_contributions.sum(&:amount_cents)

    SUPPORTER_TIERS.select { |_, cents| total >= cents }.keys.max || 0
  end

  # Whether any of it is a standing commitment rather than a one-off. Shown
  # beside the tier insignia rather than folded into it: the band is what was
  # given this month, and this is that it keeps coming -- promoting a recurring
  # contribution a band would make ten euros a month indistinguishable from
  # thirty once, which is the difference the marker exists to show.
  #
  # Source-blind, where the old rule looked only at Patreon: a standing pledge
  # is one whatever it was set up on.
  def supporter_recurring?
    active_supporter_contributions.any?(&:recurring?)
  end

  # The day the current run of support lapses, or nil when it does not lapse on
  # a date anybody can name -- either because there is nothing active, or
  # because an open-ended recurring pledge covers it and only ending that would
  # set a date. Read it next to `supporter?`, which separates those two.
  #
  # The latest date across the active contributions rather than the earliest:
  # support ends when the last of them does, not when the first one runs out.
  def supporter_until
    dates = active_supporter_contributions.map(&:active_until)
    return if dates.empty? || dates.any?(&:nil?)

    dates.max
  end

  # What the fleet tier costs to hold for a month. There is one fleet tier -- it
  # is held or it is not -- so the amount buys duration rather than a rung.
  FLEET_TIER_MONTHLY_CENTS = 500

  # The day the fleet tier runs out. A donation buys whole months at
  # `FLEET_TIER_MONTHLY_CENTS` -- ten euros is two, seven is one, four is none --
  # counted from the day it was given, and each donation extends whatever the one
  # before it had already paid for.
  #
  # Rounded down, so a part month is not bought: the tier is held or it is not,
  # and half of it is not a thing anybody has.
  #
  # Nil for a standing pledge with no end date: it keeps paying, so there is no
  # day to name -- the same answer `supporter_until` gives. Nil too when nothing
  # has bought a whole month.
  #
  # Every contribution counts, not only this month's: the date is fixed when the
  # money arrives, so a donation from August still runs into October rather than
  # vanishing at the rollover.
  #
  # Unrelated to `supporter_tier`, which bands a single month's spend and says
  # nothing about duration. The two were one calculation for a while and read as
  # a contradiction; they answer different questions and are kept apart.
  #
  # A projection for an admin to read, not yet a fact about the account: nothing
  # here changes `supporter?`, `supporter_tier`, or what `monthly_total` reports
  # to the funding goal.
  def fleet_tier_until
    return if fleet_tier_ongoing?

    started = supporter_contributions.reject { |contribution| contribution.started_at > Date.current }

    # A pledge funds the month it is billed for and banks nothing, so it runs to
    # the day it stopped. Counting a month per month it ran would also multiply
    # the wrong figure: the importer overwrites one row with the latest amount,
    # so a patron who raised five euros to ten reads as having paid ten all
    # along.
    pledged_until = started
      .select { |contribution| ended_pledge_funding_the_tier?(contribution) }
      .map(&:ended_at)
      .max

    # Donations stack on top, from the later of their own day and whatever is
    # already paid for, so one arriving mid-run extends it rather than
    # overlapping it.
    started.reject(&:recurring?).sort_by(&:started_at).reduce(pledged_until) do |paid_until, contribution|
      months = contribution.amount_cents / FLEET_TIER_MONTHLY_CENTS
      next paid_until if months.zero?

      [contribution.started_at, paid_until].compact.max + months.months
    end
  end

  # A standing pledge that covers the monthly rate funds the fleet tier for as
  # long as it stands, so there is no day to name -- a Patreon patron holds it
  # while they are paying, not from the day they stop.
  #
  # Below the rate it funds nothing, the same as a donation under five euros:
  # two euros a month does not buy a five euro month. One dated in the future
  # funds nothing yet either -- `started_at` is free to be ahead of today.
  def fleet_tier_ongoing?
    supporter_contributions.any? do |contribution|
      contribution.recurring? &&
        contribution.ended_at.nil? &&
        contribution.started_at <= Date.current &&
        contribution.amount_cents >= FLEET_TIER_MONTHLY_CENTS
    end
  end

  private def ended_pledge_funding_the_tier?(contribution)
    contribution.recurring? &&
      contribution.ended_at.present? &&
      contribution.amount_cents >= FLEET_TIER_MONTHLY_CENTS
  end

  # Generated on first view rather than at sign-up, the way a fleet's calendar
  # feed token is: most accounts never donate, and an unused key is one more
  # secret to rotate for nothing.
  def ensure_claim_key!
    return claim_key if claim_key.present?

    # Two requests arriving together would otherwise both find nothing, both
    # generate, and the loser would be handed a key that no longer exists by the
    # time they copy it. `with_lock` re-reads the row inside the transaction.
    with_lock do
      update_column(:claim_key, self.class.generate_claim_key) if claim_key.blank?
    end

    claim_key
  end

  # Nil for anything not key-shaped, so a donation message with no key is not
  # mistaken for one naming an account that does not exist.
  def self.find_by_claim_key(value)
    key = SupporterClaimKey.normalize(value)
    return if key.blank?

    find_by(claim_key: key)
  end

  def self.generate_claim_key
    loop do
      key = SupporterClaimKey.generate
      break key unless exists?(claim_key: key)
    end
  end

  # A donation can arrive before its donor has an account, or before they have
  # confirmed it -- the linker only ever matches a confirmed address, so
  # confirmation is the moment an unlinked contribution becomes resolvable.
  # Reconfirmation runs this too, which covers somebody moving their account to
  # the address they donate from.
  private def link_supporter_contributions
    SupporterContribution
      .where(user_id: nil)
      .where(payer_email: email.to_s.strip.downcase)
      .find_each { |contribution| ::Supporters::Linker.call(contribution) }
  end

  def reset_password(new_password, new_password_confirmation)
    self.password_set_manually = true
    super
  end

  def update_with_password(params, *args)
    self.password_set_manually = true if params[:password].present?
    super
  end

  def confirm_access_token
    Digest::MD5.hexdigest(Digest::MD5.hexdigest(Rails.application.credentials.confirm_access_secret!) + Digest::MD5.hexdigest(id))
  end

  STAR_SYSTEMS = {
    "STANTON" => "Stanton",
    "PYRO" => "Pyro",
    "NYX" => "Nyx",
    "TERRA" => "Terra",
    "SOL" => "Sol",
    "MAGNUS" => "Magnus",
    "CASTRA" => "Castra",
    "BREMEN" => "Bremen",
    "ODIN" => "Odin",
    "TOHIL" => "Tohil",
    "VIRGIL" => "Virgil",
    "HADRIAN" => "Hadrian",
    "OSO" => "Oso",
    "CANO" => "Cano",
    "DAVIEN" => "Davien",
    "CROSHAW" => "Croshaw",
    "RHETOR" => "Rhetor",
    "KIEL" => "Kiel",
    "BAKER" => "Baker",
    "GOSS" => "Goss",
    "ELLIS" => "Ellis",
    "NEMO" => "Nemo",
    "COREL" => "Corel",
    "KILIAN" => "Kilian",
    "IDRIS" => "Idris",
    "CENTAURI" => "Centauri",
    "CATHCART" => "Cathcart",
    "NEXUS" => "Nexus",
    "VEGA" => "Vega",
    "TIBER" => "Tiber",
    "ORION" => "Orion",
    "CALIBAN" => "Caliban",
    "HORUS" => "Horus",
    "OSIRIS" => "Osiris",
    "KELLOG" => "Kellog",
    "CHARON" => "Charon",
    "HELIOS" => "Helios",
    "HADES" => "Hades",
    "NUL" => "Nul",
    "LEIR" => "Leir",
    "BANSHEE" => "Banshee",
    "FERRON" => "Ferron",
    "OBERON" => "Oberon",
    "ELYSIUM" => "Elysium",
    "VANGUARD" => "Vanguard",
    "VIKING" => "Viking",
    "TARANIS" => "Taranis",
    "FORA" => "Fora",
    "CHRONOS" => "Chronos",
    "BRANAUGH" => "Branaugh",
    "GENESIS" => "Genesis",
    "TYROL" => "Tyrol",
    "GLIESE" => "Gliese",
    "MIN" => "Min",
    "GARRON" => "Garron",
    "TANGA" => "Tanga",
    "BACCHUS" => "Bacchus",
    "TRISE" => "Trise",
    "KABAL" => "Kabal",
    "GURZIL" => "Gurzil",
    "OYA" => "Oya",
    "TAYAC" => "Tayac",
    "KALLIS" => "Kallis",
    "VECTOR" => "Vector",
    "TAMSA" => "Tamsa",
    "VAGABOND" => "Vagabond",
    "VENDETTA" => "Vendetta",
    "VERITAS" => "Veritas",
    "VERMILION" => "Vermilion",
    "VESPER" => "Vesper",
    "VIRGO" => "Virgo",
    "VOLT" => "Volt",
    "VOODOO" => "Voodoo",
    "VULTURE" => "Vulture",
    "ORETANI" => "Oretani",
    "GEDDON" => "Geddon",
    "KINS" => "Kins",
    "AYR'KA" => "Ail'ka",
    "EL'SIN" => "El'sin",
    "RIHLAH" => "R.il'a (Rihlah)",
    "KHABARI" => "K.ap'a'ri (Khabari)",
    "KAYFA" => "Kai'pua (Kayfa)",
    "INDRA" => "Kyuk'ya (Indra)",
    "VIRTUS" => "La'uo (Virtus)",
    "MARKAHIL" => "Malkail (Markahil)",
    "PALLAS" => "Th.us'ūng (Pallas)",
    "HADUR" => "Yā'mon (Hadur)",
    "EEALUS" => "Ē'aluth (Eealus)",
    "TAL" => "T.āl",
    "YULIN" => "Yulin"
  }.freeze

  attr_accessor :destroy_fleets

  # A ledger this account recorded money in still has to add up after they
  # leave, so their participant row stays and keeps the handle it was settled
  # under instead of becoming a nameless guest.
  private def preserve_payout_participant_names
    payout_participants.where(name: nil).update_all(name: username)
  end

  # The fleet a donation supports when nothing else says otherwise: the explicit
  # choice, and failing that the fleet this person marked as their main one.
  #
  # Falling back to `primary` rather than to nothing is what makes the setting
  # work for somebody who never opens it. It is a designation they made
  # themselves -- one per account, enforced by FleetMembership#set_primary --
  # so it is a statement about which fleet is theirs, not a guess.
  def effective_supported_fleet_id
    supported_fleet_id.presence || primary_accepted_fleet_id
  end

  def effective_supported_fleet
    return supported_fleet if supported_fleet_id.present?

    ::Fleet.find_by(id: primary_accepted_fleet_id)
  end

  def supported_fleet_explicit?
    supported_fleet_id.present?
  end

  # Only an accepted, kept membership counts: a primary flag outlives the
  # membership it sits on being discarded.
  private def primary_accepted_fleet_id
    fleet_memberships.kept.accepted.find_by(primary: true)&.fleet_id
  end

  # Same rule the nomination on a contribution answers to, and checked only
  # while it is changing: somebody who later leaves the fleet must not have
  # every subsequent write to their account fail.
  private def supported_fleet_is_one_of_mine
    return if supported_fleet_id.blank?
    return unless will_save_change_to_supported_fleet_id?
    return if fleet_memberships.kept.accepted.exists?(fleet_id: supported_fleet_id)

    errors.add(:supported_fleet, :not_a_fleet_of_the_supporter)
  end

  private def check_fleet_memberships
    permanent_memberships = fleet_memberships.kept.joins(:fleet_role).where(fleet_roles: {permanent: true})
    return unless permanent_memberships.exists?

    blocking_fleets = []
    fleets_to_destroy = []
    memberships_to_delete = []

    permanent_memberships.each do |membership|
      fleet = membership.fleet
      other_admin_exists = fleet.fleet_memberships.kept
        .joins(:fleet_role)
        .where(fleet_roles: {permanent: true})
        .where.not(id: membership.id)
        .exists?

      if other_admin_exists
        memberships_to_delete << membership
      elsif fleet.fleet_memberships.kept.count == 1 || destroy_fleets
        fleets_to_destroy << [membership, fleet]
      else
        blocking_fleets << fleet.name
      end
    end

    if blocking_fleets.any?
      errors.add(:base, :has_permanent_fleet_memberships, fleets: blocking_fleets.join(", "))
      throw(:abort)
    end

    memberships_to_delete.each(&:delete)
    fleets_to_destroy.each do |membership, fleet|
      membership.delete
      fleet.destroy!
    end
    fleet_memberships.reload if memberships_to_delete.any? || fleets_to_destroy.any?
  end

  private def match_current_system
    if current_system.blank?
      self.current_system_code = nil
      return
    end

    input = current_system.strip.downcase

    match = STAR_SYSTEMS.find do |code, name|
      input == code.downcase ||
        input == name.downcase ||
        name.downcase.include?(input) ||
        input.include?(name.downcase)
    end

    self.current_system_code = match&.first
  end

  private def clear_coordinates
    self.latitude = nil
    self.longitude = nil
  end

  private def sync_sale_notify_preference
    return unless saved_change_to_sale_notify?

    pref = notification_preferences.find_or_initialize_by(notification_type: "model_on_sale")
    pref.update!(app: sale_notify?, mail: sale_notify?)
  end

  # One statement for all two dozen types. A `create!` each ran a uniqueness
  # SELECT before its INSERT -- 48 round trips on a signup -- and the row it
  # went looking for cannot be there: the user was created a moment ago, and
  # the (user_id, notification_type) pair is unique in the database.
  #
  # insert_all builds one statement from the first row's keys, so every row has
  # to carry the same ones. The defaults are merged onto a full set rather than
  # passed through as a type happens to configure them, and the timestamps are
  # set here because insert_all does not fill them in and the columns are NOT
  # NULL.
  private def create_default_notification_preferences
    now = Time.zone.now

    rows = Notification.notification_types.each_key.map do |type|
      defaults = if type == "model_on_sale" && sale_notify?
        {app: true, mail: true}
      else
        NotificationPreference.defaults_for(type)
      end

      NotificationPreference::CHANNEL_DEFAULTS
        .merge(defaults)
        .merge(user_id: id, notification_type: type, created_at: now, updated_at: now)
    end

    NotificationPreference.insert_all(rows)
  end

  private def touch_fleet_memberships
    # rubocop:disable Rails/SkipsModelValidations
    fleet_memberships.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Through the same job a connection change goes through, so co-members and
  # friends get the redaction applied on the way out and admins do not.
  private def broadcast_online_status_change
    ::Presence::BroadcastTransitionJob.perform_async(
      id, ::Presence::BroadcastTransitionJob::REASON_PREFERENCE
    )
  end

  private def notify_user
    notify_two_factor_change if saved_change_to_otp_required_for_login?

    UserMailer.username_changed(email, username).deliver_later if saved_change_to_username?
  end

  private def notify_two_factor_change
    if otp_required_for_login?
      TwoFactorMailer.enabled(email, username).deliver_later
    else
      TwoFactorMailer.disabled(email, username).deliver_later
    end
  end

  def features
    Flipper.features.filter_map do |feature|
      Flipper.enabled?(feature.name, self) ? feature.name : nil
    end
  end

  def reset_otp
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:otp_required_for_login, false)
    update_column(:encrypted_otp_secret, nil)
    update_column(:encrypted_otp_secret_iv, nil)
    update_column(:encrypted_otp_secret_salt, nil)
    update_column(:otp_backup_codes, nil)
    update_column(:otp_secret, nil)
    # rubocop:enable Rails/SkipsModelValidations
    update(otp_secret: User.generate_otp_secret)
  end

  ## TODO: remove once Deivse Two Factor upgrade to 5.x is done
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # prior versions of devise-two-factor
  # @return [String] The decrypted OTP secret
  private def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag = raw_cipher_text[-16..]

    # this alrorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new("aes-256-gcm")

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryptoin from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ""

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end

  def to_json(*_args)
    to_jbuilder_json
  end
end
