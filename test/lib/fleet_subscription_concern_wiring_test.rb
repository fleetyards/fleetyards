# frozen_string_literal: true

require "test_helper"

# A bypass here is silent: the concern treats an unresolvable fleet as "nothing
# to enforce", which is what keeps the personal surfaces free -- and therefore
# what turns any wiring mistake into free access rather than an error.
#
# Two such mistakes have already happened, so they are checked rather than
# reviewed for.
class FleetSubscriptionConcernWiringTest < ActiveSupport::TestCase
  # Controllers are autoloaded, so nothing has referenced them yet in a unit
  # test -- without this the scan finds none and every assertion below passes
  # vacuously.
  Rails.application.eager_load!

  # `ActionController::API`, not `Base` -- these are API controllers.
  GUARDED = ObjectSpace.each_object(Class).select do |klass|
    klass < ActionController::API && klass.include?(FleetSubscriptionConcern)
  rescue
    false
  end.freeze

  test "the concern is applied to something" do
    assert_operator GUARDED.size, :>, 20,
      "expected the four capabilities' controllers, found #{GUARDED.size}"
  end

  # `FleetSubscriptionConcern` is included last on the payout controllers, so
  # its `@fleet` default -- nil there -- won the lookup over the one
  # `PayoutLedgerScoped` provides. Whenever two ancestors both answer, the class
  # has to say which it means.
  test "a controller whose ancestors disagree defines its own resolver" do
    ambiguous = GUARDED.reject do |klass|
      owners = klass.ancestors.select do |mod|
        mod.method_defined?(:subscription_fleet, false) ||
          mod.private_method_defined?(:subscription_fleet, false)
      end

      owners.size < 2 || owners.first == klass
    end

    assert_empty ambiguous.map(&:name),
      "these inherit a `subscription_fleet` from more than one module without choosing"
  end

  test "every guarded controller can answer the question at all" do
    missing = GUARDED.reject { |klass| klass.private_method_defined?(:subscription_fleet) }

    assert_empty missing.map(&:name)
  end
end
