# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                        :uuid             not null, primary key
#  calendar_feed_token       :string
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
#  guilded                   :string
#  hangar_updated_at         :datetime
#  hide_owner                :boolean          default(FALSE), not null
#  homepage                  :string
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
#  purchased_vehicles_count  :integer          default(0), not null
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  rsi_handle_verified       :boolean          default(FALSE), not null
#  sale_notify               :boolean          default(FALSE)
#  sign_in_count             :integer          default(0), not null
#  tester                    :boolean          default(FALSE)
#  tracking                  :boolean          default(TRUE)
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  wanted_vehicles_count     :integer          default(0), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_users_on_calendar_feed_token   (calendar_feed_token) UNIQUE
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_last_active_at        (last_active_at)
#  index_users_on_normalized_username   (normalized_username)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
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
      assert @user.public_supporter?
    end

    test "an anonymous contribution still earns supporter status but no public badge" do
      create(:supporter_contribution, :anonymous, user: @user, started_at: Date.current)

      assert @user.supporter?
      refute @user.public_supporter?
    end

    test "a contribution that ended before this month counts for neither" do
      create(:supporter_contribution, :recurring, user: @user,
        started_at: 1.year.ago.to_date, ended_at: 2.months.ago.to_date)

      refute @user.supporter?
      refute @user.public_supporter?
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
