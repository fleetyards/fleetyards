# frozen_string_literal: true

module FeatureFlags
  # Records every write to a Flipper flag as a FeatureFlagChange.
  #
  # Flipper instruments each operation on `Feature`, and flipper's Rails engine
  # already defaults the instrumenter to ActiveSupport::Notifications -- so these
  # events are published with nothing but flipper's own log subscriber listening.
  # One subscriber here therefore covers every path that writes a flag without
  # touching any of them: /admin/features, user and fleet self-service, the
  # deploy's own sync, a console call, an e2e scenario.
  #
  # Recording from Admin::Api::V1::FeaturesController instead would be the
  # obvious place and would miss sync, self-service and the console, which is
  # exactly the history nobody can reconstruct afterwards.
  class AuditSubscriber
    EVENT_NAME = "feature_operation.flipper"

    def self.register!
      # Guarded because a second subscription would write two rows per change.
      return @subscription if @subscription

      @subscription = ActiveSupport::Notifications.subscribe(EVENT_NAME) do |*args|
        handle(args.last)
      end
    end

    def self.unregister!
      return unless @subscription

      ActiveSupport::Notifications.unsubscribe(@subscription)
      @subscription = nil
    end

    # The same event carries `enabled?`, which fires on every flag check on every
    # request -- so this runs under full read traffic and the operation test has
    # to come first and stay cheap. Everything past it happens a few times a
    # week.
    def self.handle(payload)
      return unless FeatureFlagChange::OPERATIONS.include?(payload[:operation].to_s)

      FeatureFlagChange.record!(payload)
    rescue => e
      # A flag that cannot be audited is still a flag that changed. An audit log
      # able to 500 the admin page would be worse than no audit log.
      report(e, payload)
    end

    # Reporting the failure must not become the failure. ActiveSupport delivers
    # this subscriber after Flipper has already written the gate, so an
    # exception escaping here propagates to the caller and reports a mutation
    # that succeeded as failed.
    def self.report(error, payload)
      Rails.logger.error("[FeatureFlags::AuditSubscriber] #{payload[:feature_name]} #{payload[:operation]} failed: #{error.class}: #{error.message}")
      Appsignal.report_error(error)
    rescue
      nil
    end
  end
end
