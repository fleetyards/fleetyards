# frozen_string_literal: true

# Seeds the flag history from what flipper_gates still holds, so the log does not
# start empty on the day it ships.
#
# This is a lower bound, not the truth, and cannot be anything else. The gate
# table keeps no history of its own:
#
#   * disabling a boolean gate deletes the row, so a flag switched off and on
#     again backfills as though it had only ever been on once;
#   * enabling one for everyone runs `set(clear: true)`, which deletes every
#     actor and group row first -- so the rollout that preceded a fully-open flag
#     is already gone and no backfill can recover it;
#   * `bin/feature-flags sync` removed pruned flags outright, gates and all.
#
# What it can say honestly is when each surviving gate was last written, and what
# state the flag was in once it existed. Everything after this migration is
# recorded as it happens by FeatureFlags::AuditSubscriber.
class BackfillFeatureFlagChanges < ActiveRecord::Migration[8.1]
  FEATURES = Flipper::Adapters::ActiveRecord::Feature
  GATES = Flipper::Adapters::ActiveRecord::Gate

  def up
    return if FeatureFlagChange.exists?(source: FeatureFlagChange::SOURCE_BACKFILL)

    FEATURES.order(:created_at).each { |feature| backfill(feature) }
  end

  def down
    FeatureFlagChange.where(source: FeatureFlagChange::SOURCE_BACKFILL).delete_all
  end

  # `updated_at` rather than `created_at`: a percentage gate is updated in place,
  # so its created_at is when a percentage was first set rather than when it took
  # the value the row now holds. Every other gate is written once and the two are
  # identical.
  private def backfill(feature)
    gates = GATES.where(feature_key: feature.key).order(:updated_at, :id).to_a

    record(feature.key, operation: "add", at: feature.created_at, gates: [])

    gates.each_with_index do |gate, index|
      record(
        feature.key,
        operation: "enable",
        at: gate.updated_at,
        gates: gates[0..index],
        gate_name: FeatureFlagChange::GATE_NAMES_BY_STORAGE_KEY.fetch(gate.key, gate.key),
        thing: gate.value
      )
    end
  end

  private def record(feature_key, operation:, at:, gates:, gate_name: nil, thing: nil)
    FeatureFlagChange.create!(
      feature_name: feature_key,
      operation: operation,
      gate_name: gate_name,
      thing: thing,
      state_after: state_for(gates),
      source: FeatureFlagChange::SOURCE_BACKFILL,
      created_at: at
    )
  end

  # Flipper::Feature#state, applied to the gates that existed at each step.
  #
  # A percentage of 0 is the gate's default and leaves the flag off, which is why
  # the row cannot simply be counted as present.
  private def state_for(gates)
    return FeatureFlagChange::STATE_ON if gates.any? { |gate| gate.key == "boolean" && gate.value == "true" }
    return FeatureFlagChange::STATE_CONDITIONAL if gates.any? { |gate| conditional?(gate) }

    FeatureFlagChange::STATE_OFF
  end

  private def conditional?(gate)
    return gate.value.to_i.positive? if gate.key.start_with?("percentage_of_")

    gate.value.present?
  end
end
