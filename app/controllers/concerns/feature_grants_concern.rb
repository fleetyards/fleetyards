# frozen_string_literal: true

# Reading Flipper's gates for one actor, rather than asking whether a feature is
# enabled for them.
#
# A self-service page has to tell "you switched this on" apart from "someone
# switched it on for you": the gates are ORed, so a switch that clears only the
# actor's own gate cannot undo a group's or a fleet's, and a page that offers it
# anyway reports a change nobody will see.
module FeatureGrantsConcern
  extend ActiveSupport::Concern

  # The actor's own gate — the one a self-service switch flips. Deliberately not
  # Flipper.enabled?, which a group gate or a percentage rollout satisfies too.
  def feature_actor_gate?(feature, actor)
    feature.actors_value.include?(Flipper::Types::Actor.new(actor).value)
  end

  # The groups this actor belongs to that switched the feature on. Nothing
  # outside /admin/features can reach a group gate, so naming the group is the
  # only way a page can explain why a switch is stuck.
  def feature_granting_groups(feature, actor)
    return [] if feature.groups_value.empty?

    wrapped = Flipper::Types::Actor.new(actor)
    context = Flipper::FeatureCheckContext.new(
      feature_name: feature.name,
      values: feature.gate_values,
      actors: [wrapped]
    )

    feature.enabled_groups.filter_map { |group| group.name.to_s if group.match?(wrapped, context) }
  end
end
