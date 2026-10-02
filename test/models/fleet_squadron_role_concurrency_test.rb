# frozen_string_literal: true

require "test_helper"
require "timeout"

class FleetSquadronRoleConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @fleet = create(:fleet)
  end

  teardown do
    users = @fleet.fleet_memberships.filter_map(&:user)
    @fleet.destroy!
    users.each(&:destroy!)
  end

  # Runs `work` on its own connection while this thread holds `hold` open in a
  # transaction, and returns once the worker is waiting on a lock -- the
  # interleaving that loses without the fleet lock.
  def race(hold:, work:)
    backend = Queue.new
    worker = nil

    ActiveRecord::Base.transaction do
      hold.call

      worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          backend << connection.select_value("SELECT pg_backend_pid()")
          work.call
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

    worker.value
  ensure
    worker&.join
  end

  # The worker read Member while it was still the default, so only a re-read
  # under the lock tells it the default has moved and has to be moved back.
  test "a default move waiting on another one still lands" do
    ranks = @fleet.fleet_squadron_roles.index_by(&:key)
    stale_member = FleetSquadronRole.find(ranks.fetch("member").id)

    race(
      hold: -> { FleetSquadronRole.find(ranks.fetch("officer").id).make_default! },
      work: -> { stale_member.make_default! }
    )

    assert_equal %w[member], @fleet.fleet_squadron_roles.where(default_rank: true).pluck(:key)
  end
end
