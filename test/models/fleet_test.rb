# frozen_string_literal: true

require "test_helper"

class FleetTest < ActiveSupport::TestCase
  test "#setup_default_roles! creates 3 default roles on fleet creation" do
    fleet = create(:fleet)
    assert_equal 3, fleet.fleet_roles.count
  end

  test "#default_member_role returns the last ranked role" do
    fleet = create(:fleet)
    assert_equal "Member", fleet.default_member_role.name
  end

  test "#default_member_role creates roles if none exist" do
    fleet = create(:fleet)
    fleet.fleet_roles.destroy_all
    assert_equal 0, fleet.fleet_roles.reload.count

    role = fleet.default_member_role

    assert_equal "Member", role.name
    assert_equal 3, fleet.fleet_roles.reload.count
  end

  class UrlValidationTest < FleetTest
    setup do
      user = create(:user)
      @fleet = create(:fleet, created_by: user.id)
    end

    %w[guilded homepage discord twitch youtube].each do |field|
      test "strips protocol from #{field} url" do
        @fleet.update!(field => "https://foo.bar")
        @fleet.reload
        assert_equal "foo.bar", @fleet.send(field)
      end

      test "strips double slashes from #{field} url" do
        @fleet.update!(field => "//foo.bar")
        @fleet.reload
        assert_equal "foo.bar", @fleet.send(field)
      end
    end

    test "adds ts3server protocol to ts url" do
      @fleet.update!(ts: "foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end

    test "replaces http with ts3server for ts url" do
      @fleet.update!(ts: "http://foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end

    test "replaces https with ts3server for ts url" do
      @fleet.update!(ts: "https://foo.bar")
      @fleet.reload
      assert_equal "ts3server://foo.bar", @fleet.ts
    end
  end
end
