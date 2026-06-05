# frozen_string_literal: true

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
