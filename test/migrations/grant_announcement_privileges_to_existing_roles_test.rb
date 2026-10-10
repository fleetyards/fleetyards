# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261009150100_grant_announcement_privileges_to_existing_roles.rb")

class GrantAnnouncementPrivilegesToExistingRolesTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet)
  end

  def role_with(name, access)
    role = create(:fleet_role, fleet: @fleet, name: name)
    role.update_columns(resource_access: access)
    role
  end

  test "a role that runs the membership may post announcements afterwards" do
    officer = role_with("Old officer", ["fleet:memberships:manage", "fleet:events:manage"])

    GrantAnnouncementPrivilegesToExistingRoles.new.up

    assert_includes officer.reload.resource_access, "fleet:announcements:manage"
    assert_includes officer.resource_access, "fleet:events:manage"
  end

  test "a role that only reads members is left as it was" do
    member = role_with("Old member", ["fleet:memberships:read"])

    GrantAnnouncementPrivilegesToExistingRoles.new.up

    assert_equal ["fleet:memberships:read"], member.reload.resource_access
  end

  test "running it twice grants the privilege once" do
    officer = role_with("Old officer", ["fleet:memberships:manage"])

    2.times { GrantAnnouncementPrivilegesToExistingRoles.new.up }

    assert_equal 1, officer.reload.resource_access.count("fleet:announcements:manage")
  end
end
