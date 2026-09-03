# frozen_string_literal: true

require "test_helper"

class AdminUserPrivilegesTest < ActiveSupport::TestCase
  # The failure this catches is silent: a policy asking for a privilege that is
  # not in the catalogue cannot be satisfied by any grant, so the section it
  # guards becomes super-admin-only without anybody deciding that. Fifteen
  # policies had drifted this way before the list was completed.
  test "every privilege a policy asks for can actually be granted" do
    Rails.application.eager_load!

    asking_for_the_ungrantable = admin_policies.each_with_object({}) do |policy, gaps|
      required = Array(policy.allocate.send(:resource_access)).map(&:to_s)
      missing = required - AdminUser::AVAILABLE_PRIVILEGES

      gaps[policy.name] = missing if missing.any?
    end

    assert_empty asking_for_the_ungrantable,
      "these policies require a privilege absent from AdminUser::RESOURCE_ACCESS, " \
      "so only a super admin can ever satisfy them: #{asking_for_the_ungrantable}"
  end

  test "every privilege in the catalogue is asked for by a policy" do
    Rails.application.eager_load!

    required = admin_policies.flat_map { |policy| Array(policy.allocate.send(:resource_access)).map(&:to_s) }

    # Privileges guarding something other than a BasePolicy resource: the
    # engines mounted behind the admin, and the maintenance tasks page.
    #
    # `admins` is a known inconsistency rather than a clean exception. The
    # frontend route declares `access: ["admins"]`, so granting it reveals the
    # section in the nav -- but `Admin::AdminUserPolicy` is not a BasePolicy and
    # gates on `super_admin?` outright, so every call behind it still 403s.
    # Granting the privilege therefore shows a page nobody can use. Left as-is:
    # aligning them widens who can manage admin accounts, which is a decision
    # rather than a fix.
    outside_the_policies = %w[maintenance workers pghero admins]

    assert_empty AdminUser::AVAILABLE_PRIVILEGES - required - outside_the_policies,
      "these privileges can be granted but nothing checks them"
  end

  test "the catalogue has no duplicates across its groups" do
    assert_equal AdminUser::AVAILABLE_PRIVILEGES.uniq, AdminUser::AVAILABLE_PRIVILEGES
  end

  private def admin_policies
    Admin.constants.filter_map do |name|
      const = Admin.const_get(name)

      next unless const.is_a?(Class) && const < Admin::BasePolicy
      # BasePolicy itself raises NotImplementedError rather than naming one.
      next if const == Admin::BasePolicy

      const
    end
  end
end
