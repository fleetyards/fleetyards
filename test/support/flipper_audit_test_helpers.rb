# frozen_string_literal: true

module FlipperAuditTestHelpers
  # Runs the block against a Flipper instance that publishes its operations.
  #
  # `flipper/test_help` builds the test instance as `Flipper.new(config.adapter)`
  # with no instrumenter argument, so it gets Instrumenters::Noop and
  # `feature_operation.flipper` never fires in the test environment --
  # FeatureFlags::AuditSubscriber would look dead no matter what it did. The
  # engine gives development and production ActiveSupport::Notifications by
  # default, so this restores what those environments already do rather than
  # inventing a setup for the tests.
  #
  # Opt-in per test rather than global: a great many tests enable a flag in
  # setup, and every one of them would otherwise write audit rows nothing
  # asserts on.
  def with_flag_auditing
    previous = Flipper.instance
    Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

    yield
  ensure
    Flipper.instance = previous
  end
end

module ActiveSupport
  class TestCase
    include FlipperAuditTestHelpers
  end
end
