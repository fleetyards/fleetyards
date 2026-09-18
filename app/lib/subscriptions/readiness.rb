# frozen_string_literal: true

module Subscriptions
  # Who loses access the day enforcement is switched on.
  #
  # D16 gates the switch on this number rather than on a calendar: the fleets
  # reaching a premium surface today that have neither a subscription nor a
  # grace row. Read it before the announcement and again before the date.
  #
  # The reason it exists is a measurement, not a principle. Zero of sixteen
  # contributions carried a `user_id` when this was planned, so nothing links
  # the people paying today to the fleets they are in -- and flipping the flag
  # without having read this is how they lose access on announcement day.
  class Readiness
    # Every flag that gates a premium capability, including the second one on
    # tours. Deliberately the union rather than one flag per capability: a
    # fleet holding any of them has been reaching functionality that is about
    # to cost something, and for a grace window the generous reading is the
    # correct one.
    FLAGS = %w[
      fleet_contracts
      fleet_mission_builder
      fleet_logistics
      fleet_tours
      tour_payouts
    ].freeze

    def self.call(...) = new(...).call

    def initialize(on: Date.current)
      @on = on
    end

    def call
      {
        on: @on,
        globally_on:,
        gated_fleet_ids:,
        subscribed_fleet_ids:,
        unready_fleet_ids:
      }
    end

    # A flag switched on for everybody has no actor list to read, and every
    # fleet is reaching it. Reported rather than folded into the counts: it
    # means the figures below describe the wrong population, and it is a
    # decision for a person rather than something to paper over.
    def globally_on
      @globally_on ||= FLAGS.select { |flag| Flipper.feature(flag).boolean_value }
    end

    # Both halves of the gate. A fleet's own actor gate is the obvious one; a
    # member's personal gate is the one that gets forgotten, and it grants just
    # as well -- `Flipper.enabled?(flag, user, fleet)` ORs, so a user carrying
    # the gate has been reaching the surface on every fleet they belong to.
    def gated_fleet_ids
      @gated_fleet_ids ||= (fleet_ids_from_gates + fleet_ids_from_member_gates).uniq
    end

    def subscribed_fleet_ids
      @subscribed_fleet_ids ||=
        FleetSubscription.active_on(@on).where(fleet_id: gated_fleet_ids).distinct.pluck(:fleet_id)
    end

    def unready_fleet_ids
      @unready_fleet_ids ||= gated_fleet_ids - subscribed_fleet_ids
    end

    private def actor_ids
      @actor_ids ||= FLAGS.flat_map { |flag| Flipper.feature(flag).actors_value.to_a }.uniq
    end

    private def ids_for(type)
      actor_ids.filter_map do |flipper_id|
        actor_type, id = flipper_id.split(";", 2)
        id if actor_type == type
      end
    end

    # Filtered through the table rather than trusted: a gate outlives the row
    # it names, so a deleted fleet is still in the gate list forever.
    private def fleet_ids_from_gates
      Fleet.where(id: ids_for("Fleet")).pluck(:id)
    end

    private def fleet_ids_from_member_gates
      user_ids = User.where(id: ids_for("User")).pluck(:id)
      return [] if user_ids.empty?

      FleetMembership.where(user_id: user_ids, aasm_state: "accepted").distinct.pluck(:fleet_id)
    end
  end
end
