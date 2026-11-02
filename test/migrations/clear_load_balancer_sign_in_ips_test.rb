# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261102210000_clear_load_balancer_sign_in_ips.rb")

class ClearLoadBalancerSignInIpsTest < ActiveSupport::TestCase
  test "clears the load balancer's address and keeps visitors' addresses" do
    Rails.application.config.action_dispatch.stubs(:trusted_proxies).returns([IPAddr.new("91.98.1.57")])
    behind = create(:user)
    behind.update_columns(current_sign_in_ip: "91.98.1.57", last_sign_in_ip: "84.175.181.71")
    visitor = create(:user)
    visitor.update_columns(current_sign_in_ip: "203.0.113.7", last_sign_in_ip: "91.98.1.57")
    admin = create(:admin_user)
    admin.update_columns(current_sign_in_ip: "91.98.1.57")

    ClearLoadBalancerSignInIps.new.up

    assert_nil behind.reload.current_sign_in_ip
    assert_equal "84.175.181.71", behind.last_sign_in_ip
    assert_equal "203.0.113.7", visitor.reload.current_sign_in_ip
    assert_nil visitor.last_sign_in_ip
    assert_nil admin.reload.current_sign_in_ip
  end

  test "does nothing where no load balancer is configured" do
    Rails.application.config.action_dispatch.stubs(:trusted_proxies).returns(nil)
    user = create(:user)
    user.update_columns(current_sign_in_ip: "91.98.1.57")

    ClearLoadBalancerSignInIps.new.up

    assert_equal "91.98.1.57", user.reload.current_sign_in_ip
  end
end
