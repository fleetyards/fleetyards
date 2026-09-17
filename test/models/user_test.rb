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
#  inventory_transfer_policy :integer          default(0), not null
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
#  index_users_on_unlock_token           (unlock_token) UNIQUE
#  index_users_on_username               (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  class DestroyTest < UserTest
    setup do
      @user = create(:user)
    end

    test "destroys a user without fleet memberships" do
      assert @user.destroy
      refute User.exists?(@user.id)
    end

    test "destroys a user who is the sole member of a fleet with a permanent role" do
      fleet = create(:fleet, admins: [@user])

      assert @user.destroy
      refute User.exists?(@user.id)
      refute Fleet.exists?(fleet.id)
    end

    test "prevents destruction when user has a permanent role in a multi-member fleet" do
      other_user = create(:user)
      fleet = create(:fleet, admins: [@user], members: [other_user])

      assert_equal false, @user.destroy
      assert_includes @user.errors[:base], I18n.t("activerecord.errors.models.user.attributes.base.has_permanent_fleet_memberships", fleets: fleet.name)
      assert User.exists?(@user.id)
    end

    test "destroys a user with a non-permanent fleet role in a multi-member fleet" do
      other_user = create(:user)
      create(:fleet, admins: [other_user], members: [@user])

      assert @user.destroy
      refute User.exists?(@user.id)
    end

    test "destroys the user and multi-member fleet when destroy_fleets is set" do
      other_user = create(:user)
      fleet = create(:fleet, admins: [@user], members: [other_user])

      @user.destroy_fleets = true

      assert @user.destroy
      refute User.exists?(@user.id)
      refute Fleet.exists?(fleet.id)
    end

    test "returns a symbolic error code for has_permanent_fleet_memberships" do
      other_user = create(:user)
      create(:fleet, admins: [@user], members: [other_user])

      assert_equal false, @user.destroy
      error = @user.errors.where(:base).first
      assert_equal :has_permanent_fleet_memberships, error.type
    end

    test "destroys a user who shares admin role with another admin" do
      co_admin = create(:user)
      fleet = create(:fleet, admins: [@user, co_admin])

      assert @user.destroy
      refute User.exists?(@user.id)
      assert Fleet.exists?(fleet.id)
      assert fleet.fleet_memberships.where(user: co_admin).exists?
    end

    test "blocks only on fleets where the user is the sole admin" do
      co_admin = create(:user)
      other_member = create(:user)
      shared_admin_fleet = create(:fleet, name: "SharedAdmins", admins: [@user, co_admin])
      sole_admin_fleet = create(:fleet, name: "SoleAdmin", admins: [@user], members: [other_member])

      assert_equal false, @user.destroy
      error = @user.errors.where(:base).first
      assert_equal :has_permanent_fleet_memberships, error.type
      assert_equal "SoleAdmin", error.options[:fleets]
      assert Fleet.exists?(shared_admin_fleet.id)
      assert Fleet.exists?(sole_admin_fleet.id)
    end
  end

  class SupporterTest < UserTest
    setup do
      @user = create(:user)
    end

    test "a live contribution makes the user a supporter" do
      create(:supporter_contribution, user: @user, started_at: Date.current)

      assert @user.supporter?
    end

    # Anonymity decides whether the contribution is named on the supporters
    # page, and nothing else. Both halves are asserted here because the rule is
    # only meaningful as a pair.
    test "an anonymous contribution earns the badge and stays unnamed" do
      contribution = create(:supporter_contribution, :anonymous, user: @user, started_at: Date.current)

      assert @user.supporter?
      assert_nil contribution.public_name
    end

    test "a named contribution earns the badge and is named" do
      contribution = create(:supporter_contribution, user: @user, name: "Jo", started_at: Date.current)

      assert @user.supporter?
      assert_equal "Jo", contribution.public_name
    end

    test "a contribution that ended before this month earns nothing" do
      create(:supporter_contribution, :recurring, user: @user,
        started_at: 1.year.ago.to_date, ended_at: 2.months.ago.to_date)

      refute @user.supporter?
    end

    # A donation can land before its donor has an account. The linker only ever
    # matches a confirmed address, so confirmation is the moment it resolves.
    test "confirming an account claims a contribution that arrived first" do
      contribution = create(:supporter_contribution, payer_email: "later@example.test")
      user = create(:user, email: "later@example.test", confirmed_at: nil)

      assert_nil contribution.reload.user

      user.update!(confirmed_at: Time.current)

      assert_equal user, contribution.reload.user
    end

    test "confirming claims nothing that is already linked or addressed elsewhere" do
      mine = create(:user, confirmed_at: Time.current)
      taken = create(:supporter_contribution, payer_email: "later@example.test", user: mine)
      other = create(:supporter_contribution, payer_email: "somebody@example.test")

      create(:user, email: "later@example.test", confirmed_at: nil).update!(confirmed_at: Time.current)

      assert_equal mine, taken.reload.user
      assert_nil other.reload.user
    end

    # Devise's reconfirmation changes confirmed_at as well as email, so this is
    # the path the confirmation arm already covered. Asserted because it is the
    # one a reviewer expected to be broken.
    test "reconfirming to a new address claims a contribution for it" do
      contribution = create(:supporter_contribution, payer_email: "moved@example.test")
      user = create(:user, confirmed_at: Time.current)

      user.update!(email: "moved@example.test")
      user.confirm

      assert_equal user, contribution.reload.user
    end

    # The case confirmed_at alone would miss: an admin moving an account.
    test "an admin moving an address without reconfirmation still claims it" do
      contribution = create(:supporter_contribution, payer_email: "forced@example.test")
      user = create(:user, confirmed_at: Time.current)

      user.skip_reconfirmation!
      user.update!(email: "forced@example.test")

      assert_equal user, contribution.reload.user
    end

    # Platforms are not careful with whitespace, and an address with a stray
    # space matches nothing without a word of warning.
    test "a payer email with surrounding space is still claimed" do
      contribution = create(:supporter_contribution, payer_email: "  Spaced@Example.test  ")

      assert_equal "spaced@example.test", contribution.reload.payer_email

      user = create(:user, email: "spaced@example.test", confirmed_at: Time.current)

      assert_equal user, contribution.reload.user
    end

    # The three supporter answers share one loaded set, and `reload` clears the
    # association cache but not a plain ivar -- so the clearing is explicit.
    test "reloading re-reads the contributions the answers are drawn from" do
      refute @user.supporter?

      create(:supporter_contribution, user: @user, started_at: Date.current)

      refute @user.supporter?
      assert @user.reload.supporter?
    end

    # The admin user list renders supporter status per row, so the preloaded
    # path has to answer from memory -- otherwise a page of thirty users pays
    # for thirty round trips that the preload was supposed to replace.
    test "a preloaded association answers without asking the database again" do
      create(:supporter_contribution, user: @user, started_at: Date.current)

      user = User.includes(:supporter_contributions).find(@user.id)

      queries = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries += 1 unless /SCHEMA|TRANSACTION/.match?(payload[:name].to_s)
      end

      begin
        assert user.supporter?
        assert_equal 2, user.supporter_tier
        assert_equal Date.current.end_of_month, user.supporter_until
        user.fleet_tier_until
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      assert_equal 0, queries
    end

    # Ten euros at five a month is two months, counted from the day it was given.
    test "a donation buys whole months from the day it was given" do
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.new(2026, 9, 15))

      travel_to Date.new(2026, 9, 17) do
        assert_equal Date.new(2026, 11, 15), @user.reload.fleet_tier_until
      end
    end

    # Whole months only: seven fifty buys one, not one and a half. The tier is
    # held or it is not, so there are no part months and no day arithmetic.
    test "a part month is not bought" do
      create(:supporter_contribution, user: @user,
        amount_cents: 750, started_at: Date.new(2026, 9, 15))

      travel_to Date.new(2026, 9, 17) do
        assert_equal Date.new(2026, 10, 15), @user.reload.fleet_tier_until
      end
    end

    test "an amount under the monthly rate buys nothing" do
      create(:supporter_contribution, user: @user,
        amount_cents: 400, started_at: Date.new(2026, 9, 15))

      travel_to Date.new(2026, 9, 17) do
        assert_nil @user.reload.fleet_tier_until
      end
    end

    # The date is fixed when the money arrives, so it does not vanish at the
    # month rollover the way supporter status does.
    test "a donation from a past month still runs" do
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.new(2026, 8, 15))

      travel_to Date.new(2026, 9, 17) do
        assert_equal Date.new(2026, 10, 15), @user.reload.fleet_tier_until
      end
    end

    # A donation arriving while the last one is still running adds to it rather
    # than overlapping it.
    test "donations stack onto what is already paid for" do
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.new(2026, 8, 15))
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.new(2026, 9, 1))

      travel_to Date.new(2026, 9, 17) do
        # August's two months run to 15 October; September's start there.
        assert_equal Date.new(2026, 12, 15), @user.reload.fleet_tier_until
      end
    end

    # It keeps paying, so there is no day to name -- and naming one meant a
    # standing pledge a year old reporting a date eleven months past.
    test "a standing pledge has no run-out date" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 500, started_at: 1.year.ago.to_date, ended_at: nil)

      assert @user.reload.fleet_tier_ongoing?
      assert_nil @user.fleet_tier_until
    end

    # A Patreon pledge is written recurring and open-ended while it stands, so
    # this is the case the admin sees for every active patron.
    test "an active patron holds the fleet tier while paying" do
      create(:supporter_contribution, :patreon, user: @user,
        amount_cents: 500, started_at: Date.new(2026, 1, 10), ended_at: nil)

      assert @user.reload.fleet_tier_ongoing?
    end

    # Two euros a month does not buy a five euro month, so it funds nothing --
    # the same answer a four euro donation gets.
    test "a standing pledge under the rate funds nothing" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 200, started_at: 1.year.ago.to_date, ended_at: nil)

      refute @user.reload.fleet_tier_ongoing?
      assert_nil @user.fleet_tier_until
    end

    # The pledge is worth nothing, but it must not swallow what was bought
    # outright alongside it.
    test "a sub-rate pledge leaves a donation's months alone" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 200, started_at: Date.new(2026, 1, 10), ended_at: nil)
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.new(2026, 9, 15))

      travel_to Date.new(2026, 9, 17) do
        refute @user.reload.fleet_tier_ongoing?
        assert_equal Date.new(2026, 11, 15), @user.fleet_tier_until
      end
    end

    test "nothing standing is not ongoing" do
      refute @user.fleet_tier_ongoing?
    end

    # A pledge funds the month it is billed for and banks nothing, so it runs to
    # the day it stopped.
    test "an ended pledge runs to the day it stopped" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 500,
        started_at: Date.new(2026, 1, 10), ended_at: Date.new(2026, 8, 10))

      travel_to Date.new(2026, 9, 17) do
        assert_equal Date.new(2026, 8, 10), @user.reload.fleet_tier_until
      end
    end

    # The importer overwrites one row with the latest amount, so counting a
    # month per month it ran would read a patron who raised five euros to ten as
    # having paid ten all along.
    test "a raised pledge does not backdate its new amount" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 1000,
        started_at: Date.new(2026, 1, 10), ended_at: Date.new(2026, 8, 10))

      travel_to Date.new(2026, 9, 17) do
        assert_equal Date.new(2026, 8, 10), @user.reload.fleet_tier_until
      end
    end

    # `started_at` is free to be ahead of today, and a pledge that has not begun
    # funds nothing yet.
    test "a pledge dated in the future is not yet standing" do
      create(:supporter_contribution, :recurring, user: @user,
        amount_cents: 500, started_at: Date.current + 1.month, ended_at: nil)

      refute @user.reload.fleet_tier_ongoing?
      assert_nil @user.fleet_tier_until
    end

    test "a donation dated in the future buys nothing yet" do
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.current + 1.month)

      assert_nil @user.reload.fleet_tier_until
    end

    # The band a month's spend falls in, and how long that money lasts, are two
    # questions. Nothing here moves the tier.
    test "the fleet tier does not disturb the supporter tier" do
      create(:supporter_contribution, user: @user,
        amount_cents: 1000, started_at: Date.current)

      assert_equal 2, @user.reload.supporter_tier
      assert_equal Date.current.end_of_month, @user.supporter_until
    end

    test "no contributions means no fleet tier" do
      assert_nil @user.fleet_tier_until
    end

    test "nothing active has no expiry to name" do
      assert_nil @user.supporter_until
    end

    test "a one-off lapses at the end of the month it arrived in" do
      create(:supporter_contribution, user: @user, started_at: Date.current)

      assert_equal Date.current.end_of_month, @user.reload.supporter_until
    end

    test "an open-ended recurring pledge has no expiry to name" do
      create(:supporter_contribution, :recurring, user: @user,
        started_at: 1.year.ago.to_date, ended_at: nil)

      assert @user.reload.supporter?
      assert_nil @user.supporter_until
    end

    # The month is the unit, so an end date part-way through one still covers the
    # rest of it.
    test "an ended recurring pledge lapses at the end of its final month" do
      ends_on = Date.current.next_month.beginning_of_month + 4

      create(:supporter_contribution, :recurring, user: @user,
        started_at: 1.year.ago.to_date, ended_at: ends_on)

      assert_equal ends_on.end_of_month, @user.reload.supporter_until
    end

    # Support ends when the last contribution does, not when the first one runs
    # out -- an extra one-off must never shorten a pledge that outlives it.
    test "the latest active contribution sets the expiry" do
      later = Date.current.next_month.end_of_month

      create(:supporter_contribution, user: @user, started_at: Date.current)
      create(:supporter_contribution, :recurring, user: @user,
        started_at: 1.year.ago.to_date, ended_at: later)

      assert_equal later, @user.reload.supporter_until
    end

    test "no contributions is tier zero" do
      assert_equal 0, @user.supporter_tier
    end

    test "the tier follows this month's total" do
      create(:supporter_contribution, user: @user, amount_cents: 100, started_at: Date.current)

      assert_equal 1, @user.reload.supporter_tier

      create(:supporter_contribution, user: @user, amount_cents: 400, started_at: Date.current)

      assert_equal 2, @user.reload.supporter_tier
    end

    test "a contribution below the first threshold earns a badge but no tier" do
      create(:supporter_contribution, user: @user, amount_cents: 50, started_at: Date.current)

      assert @user.supporter?
      assert_equal 0, @user.reload.supporter_tier
    end

    # The second tier is for the commitment, not for what the exchange rate did
    # to it in a given month.
    test "a recurring Patreon pledge is tier two whatever it converted to" do
      create(:supporter_contribution, :patreon, user: @user, amount_cents: 120,
        started_at: 1.year.ago.to_date, ended_at: nil)

      assert_equal 2, @user.reload.supporter_tier
    end

    test "a one-off Patreon contribution is not promoted" do
      create(:supporter_contribution, :patreon, user: @user, amount_cents: 120,
        recurring: false, started_at: Date.current)

      assert_equal 1, @user.reload.supporter_tier
    end

    test "last month's contributions do not count toward the tier" do
      create(:supporter_contribution, user: @user, amount_cents: 900,
        started_at: 2.months.ago.to_date)

      assert_equal 0, @user.reload.supporter_tier
    end

    test "an unlinked contribution belongs to nobody" do
      create(:supporter_contribution, started_at: Date.current)

      refute @user.supporter?
    end

    test "destroying the account keeps the contribution and drops the link" do
      contribution = create(:supporter_contribution, user: @user)

      assert @user.destroy

      assert SupporterContribution.exists?(contribution.id)
      assert_nil contribution.reload.user_id
    end
  end

  # Written with the rows going in through insert_all, which skips the
  # validations and the timestamp defaults a create! would have handled.
  class DefaultNotificationPreferencesTest < UserTest
    test "a new user gets one preference per notification type" do
      user = create(:user)

      assert_equal Notification.notification_types.keys.sort,
        user.notification_preferences.pluck(:notification_type).sort
    end

    test "each preference carries the defaults its type declares" do
      user = create(:user, sale_notify: false)

      expected = Notification.notification_types.each_key.to_h do |type|
        [type, NotificationPreference.defaults_for(type).values_at(:app, :mail, :push)]
      end

      actual = user.notification_preferences.to_h do |preference|
        [preference.notification_type, [preference.app, preference.mail, preference.push]]
      end

      assert_equal expected, actual
    end

    # The sale toggle predates the preferences and still seeds this one.
    test "sale_notify turns the on-sale preference on for both channels" do
      preference = create(:user, sale_notify: true)
        .notification_preferences
        .find_by(notification_type: "model_on_sale")

      assert preference.app
      assert preference.mail
      assert_not preference.push
    end

    test "the rows are timestamped" do
      preference = create(:user).notification_preferences.first

      assert_not_nil preference.created_at
      assert_not_nil preference.updated_at
    end
  end

  class UrlValidationTest < UserTest
    setup do
      @user = create(:user)
    end

    %w[guilded homepage discord twitch youtube].each do |field|
      test "strips protocol from #{field} url" do
        @user.update(field => "https://foo.bar")
        @user.reload
        assert_equal "foo.bar", @user.send(field)
      end

      test "strips double slashes from #{field} url" do
        @user.update(field => "//foo.bar")
        @user.reload
        assert_equal "foo.bar", @user.send(field)
      end

      test "strips http from #{field} url" do
        @user.update(field => "http://foo.bar")
        @user.reload
        assert_equal "foo.bar", @user.send(field)
      end
    end
  end
end

# `counter_cache: true` belongs on a `belongs_to`, and `Vehicle belongs_to :user`
# never declared it -- so on these two scoped `has_many`s it maintained nothing,
# while still making the reflection claim a cached counter with no column behind
# it. `size` then raised `NoMethodError` inside `counter_cache_column`, where
# `count` and `length` answered correctly.
class UserVehicleCountingTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    create_list(:vehicle, 3, user: @user, wanted: false)
    create(:vehicle, user: @user, wanted: true)
  end

  test "counts the hangar and the wishlist every way of asking" do
    user = User.find(@user.id)

    assert_equal 3, user.purchased_vehicles.size
    assert_equal 3, user.purchased_vehicles.count
    assert_equal 3, user.purchased_vehicles.length

    assert_equal 1, user.wanted_vehicles.size
    assert_equal 1, user.wanted_vehicles.count
    assert_equal 1, user.wanted_vehicles.length
  end

  test "claims no cached counter for either association" do
    %i[purchased_vehicles wanted_vehicles].each do |association|
      assert_not User.reflect_on_association(association).has_cached_counter?,
        "#{association} claims a cached counter, which has no column behind it"
    end
  end
end

# The two counter columns are still in the schema but retired: ignored a release
# ahead of the migration that drops them, so the release the pre-deploy hook
# migrates out from under has already stopped selecting them.
class UserRetiredCounterColumnsTest < ActiveSupport::TestCase
  RETIRED_COLUMNS = %w[purchased_vehicles_count wanted_vehicles_count]

  test "does not select the retired columns" do
    RETIRED_COLUMNS.each do |column|
      assert_not_includes User.column_names, column
    end

    assert_not_includes User.all.to_sql, "purchased_vehicles_count"
  end

  test "still writes a row the columns are not null on" do
    user = create(:user)

    row = ActiveRecord::Base.connection.select_one(
      "SELECT purchased_vehicles_count, wanted_vehicles_count FROM users WHERE id = '#{user.id}'"
    )

    assert_equal 0, row["purchased_vehicles_count"]
    assert_equal 0, row["wanted_vehicles_count"]
  end

  test "does not offer a retired column as a filter" do
    RETIRED_COLUMNS.each do |column|
      assert_not_includes User.ransackable_attributes, column
    end
  end
  test "#ensure_claim_key! generates once and is stable afterwards" do
    user = create(:user)

    assert_nil user.claim_key

    key = user.ensure_claim_key!

    assert_match(/\AFY-[0-9A-Z]{4}-[0-9A-Z]{4}\z/, key)
    assert_equal key, user.reload.claim_key
    assert_equal key, user.ensure_claim_key!
  end

  test ".find_by_claim_key accepts what a supporter is likely to type" do
    user = create(:user)
    key = user.ensure_claim_key!

    assert_equal user, User.find_by_claim_key(key)
    assert_equal user, User.find_by_claim_key(key.downcase)
    assert_equal user, User.find_by_claim_key(key.delete("-"))
  end

  test ".find_by_claim_key returns nil for a non-key and for an unclaimed key" do
    create(:user).ensure_claim_key!

    assert_nil User.find_by_claim_key("hello")
    assert_nil User.find_by_claim_key(nil)
    assert_nil User.find_by_claim_key("FY-0000-0000")
  end
end
