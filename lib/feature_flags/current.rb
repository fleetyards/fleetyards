# frozen_string_literal: true

module FeatureFlags
  # Who is changing a flag, and through which surface.
  #
  # The `feature_operation.flipper` notification carries the flag and the gate
  # but nothing about the caller, so attribution has to be put somewhere the
  # subscriber can reach. `ActiveSupport::CurrentAttributes` rather than a
  # thread-local of our own, because it is reset for us at the end of every
  # request and every job -- an admin set for one request cannot leak into the
  # next one on the same thread. The same reason Admin::Api::BaseController
  # already sets PaperTrail's whodunnit per request.
  #
  # Nothing sets this by default, and unset is meaningful: a flag changed from a
  # console has no surface and no actor, and FeatureFlagChange records it as
  # `console`.
  class Current < ActiveSupport::CurrentAttributes
    attribute :source, :admin_user, :user

    # Sets the surface for the duration of the block and restores whatever was
    # there before, so a nested write -- sync running inside a request, a
    # console call inside a job -- cannot strand the outer value.
    def self.with(source:, admin_user: nil, user: nil)
      previous = [self.source, self.admin_user, self.user]

      self.source = source.to_s
      self.admin_user = admin_user
      self.user = user

      yield
    ensure
      self.source, self.admin_user, self.user = previous
    end
  end
end
