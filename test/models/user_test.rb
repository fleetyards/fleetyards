# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                        :uuid             not null, primary key
#  confirmation_sent_at      :datetime
#  confirmation_token        :string(255)
#  confirmed_at              :datetime
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  current_system            :string
#  current_system_code       :string
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
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
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
