# frozen_string_literal: true

require "test_helper"
require "timeout"

class FleetSquadronMembershipConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @fleet = create(:fleet)
    @membership = create(:fleet_membership, :accepted, fleet: @fleet)
    @squadrons = create_list(:fleet_squadron, 2, fleet: @fleet)
  end

  teardown do
    users = @fleet.fleet_memberships.filter_map(&:user)
    @fleet.destroy!
    users.each(&:destroy!)
  end

  test "concurrent ordinary squadron joins commit only one membership" do
    backend = Queue.new
    worker = nil

    FleetSquadronMembership.transaction do
      create(:fleet_squadron_membership, fleet_squadron: @squadrons.first, fleet_membership: @membership)

      worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          row = FleetSquadronMembership.new(fleet_squadron_id: @squadrons.last.id, fleet_membership_id: @membership.id)
          backend << connection.select_value("SELECT pg_backend_pid()")
          [row.save, row.errors.details]
        end
      end

      pid = backend.pop
      # The competing save must reach the first transaction's lock before it
      # commits. Without the validation lock it waits only after inserting.
      # Uncached, because the executor the test runs in turns the query cache
      # on and every poll would read back the first answer.
      Timeout.timeout(10) do
        loop do
          blocked = ActiveRecord::Base.uncached do
            ActiveRecord::Base.connection.select_value("SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))").positive?
          end
          break if blocked

          sleep 0.01
        end
      end
    end

    saved, errors = worker.value
    assert_not saved
    assert_equal :exclusive_conflict, errors.fetch(:fleet_squadron).first.fetch(:error)
    assert_equal 1, FleetSquadronMembership.where(fleet_membership_id: @membership.id).count
  ensure
    worker&.join
  end

  test "concurrent promotions to Leader commit only one Leader" do
    squadron = @squadrons.first
    leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
    rows = create_list(:fleet_squadron_membership, 2, fleet_squadron: squadron)
    backend = Queue.new
    worker = nil

    FleetSquadronMembership.transaction do
      rows.first.update!(fleet_squadron_role: leader)

      worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          row = FleetSquadronMembership.find(rows.last.id)
          backend << connection.select_value("SELECT pg_backend_pid()")
          [row.update(fleet_squadron_role: leader), row.errors.details]
        end
      end

      pid = backend.pop
      Timeout.timeout(10) do
        loop do
          blocked = ActiveRecord::Base.uncached do
            ActiveRecord::Base.connection.select_value("SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))").positive?
          end
          break if blocked

          sleep 0.01
        end
      end
    end

    saved, errors = worker.value
    assert_not saved
    assert_equal :single_holder_taken, errors.fetch(:fleet_squadron_role).first.fetch(:error)
    assert_equal 1, FleetSquadronMembership.where(fleet_squadron: squadron, fleet_squadron_role: leader).count
  ensure
    worker&.join
  end
end
