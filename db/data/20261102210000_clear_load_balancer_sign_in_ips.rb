# frozen_string_literal: true

# Before the load balancer was trusted, every sign-in recorded its address
# instead of the visitor's, and it stays on an account until that account
# signs in again. It says nothing about the visitor, so it is cleared.
class ClearLoadBalancerSignInIps < ActiveRecord::Migration[8.1]
  COLUMNS = %w[current_sign_in_ip last_sign_in_ip].freeze

  def up
    addresses = Array(Rails.application.config.action_dispatch.trusted_proxies).map(&:to_s)
    return if addresses.empty?

    [User, AdminUser].each do |model|
      COLUMNS.each do |column|
        model.where(column => addresses).update_all(column => nil)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
