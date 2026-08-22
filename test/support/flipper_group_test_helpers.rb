# frozen_string_literal: true

module FlipperGroupTestHelpers
  # Registers a Flipper group for the duration of the block.
  #
  # The app's own groups match users (`testers`, `admins`), so the fleet side has
  # no real group to test against. The registry is swapped rather than added to
  # because Flipper.register raises on a duplicate name, and unregistering clears
  # every group — including the ones an initializer set up and will not set up
  # again.
  def with_flipper_group(name, matcher)
    registered = Flipper.groups_registry
    Flipper.groups_registry = Flipper::Registry.new
    Flipper.register(name, &matcher)

    yield
  ensure
    Flipper.groups_registry = registered
  end
end

module ActionDispatch
  class IntegrationTest
    include FlipperGroupTestHelpers
  end
end
