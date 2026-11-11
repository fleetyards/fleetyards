# frozen_string_literal: true

module MissionTeams
  # Copies a template or flight team's ships and slots -- the allowed models of
  # every ship and the members each slot is meant for included -- into a team
  # of an event or of another template. The copy
  # stands on its own: nothing links back except the `source_*` columns an
  # event keeps, so editing the source later changes nothing that was built
  # from it.
  class Copier
    TARGETS = {
      "FleetEventTeam" => {
        ships: :fleet_event_ships,
        slots: :fleet_event_slots,
        ship_models: :fleet_event_ship_models,
        candidates: :fleet_event_slot_candidates,
        sources: true
      },
      "MissionTeam" => {
        ships: :mission_ships,
        slots: :mission_slots,
        ship_models: :mission_ship_models,
        candidates: :mission_slot_candidates,
        sources: false
      }
    }.freeze

    SHIP_ATTRIBUTES = %i[
      model_id title description classification foci min_size max_size min_crew min_cargo
    ].freeze

    SLOT_ATTRIBUTES = %i[model_position_id title description].freeze

    SLOT_PRELOADS = [
      :model_position,
      {mission_slot_candidates: SlotCandidate::RENDER_PRELOADS}
    ].freeze

    TEAM_PRELOADS = [
      {mission_slots: SLOT_PRELOADS},
      {mission_ships: [:model, :mission_ship_models, {mission_slots: SLOT_PRELOADS}]}
    ].freeze

    def self.preload(teams)
      teams.includes(*TEAM_PRELOADS)
    end

    attr_reader :source, :target

    def initialize(source, target)
      @source = source
      @target = target
      @config = TARGETS.fetch(target.class.name)
    end

    # Appended after whatever the target already holds, so a team that had
    # slots typed into it keeps them first.
    def copy!
      slot_offset = next_position(target.public_send(@config[:slots]))
      ship_offset = next_position(target.public_send(@config[:ships]))

      source.mission_slots.sort_by(&:position).each do |slot|
        copy_slot(slot, target, slot_offset)
      end

      source.mission_ships.sort_by(&:position).each do |ship|
        copy_ship(ship, ship_offset)
      end

      target
    end

    private def copy_ship(ship, offset)
      copy = target.public_send(@config[:ships]).new(
        ship.slice(*SHIP_ATTRIBUTES).merge(position: ship.position + offset)
      )
      copy.source_ship_id = ship.id if @config[:sources]

      # Before the save, and not only so the copy arrives with the list: a spot
      # whose whole spec is a list has nothing in its columns, so saving first
      # left model_or_filter_required with nothing to accept.
      ship.mission_ship_models.sort_by(&:position).each_with_index do |allowed, index|
        copy.public_send(@config[:ship_models]).build(model_id: allowed.model_id, position: index)
      end

      copy.save!

      ship.mission_slots.sort_by(&:position).each do |slot|
        copy_slot(slot, copy, 0)
      end
    end

    private def copy_slot(slot, slottable, offset)
      attributes = slot.slice(*SLOT_ATTRIBUTES).merge(position: slot.position + offset)
      attributes[:source_slot_id] = slot.id if @config[:sources]

      copy = slottable.public_send(@config[:slots]).create!(attributes)

      slot.mission_slot_candidates.sort_by(&:position).each do |candidate|
        copy_candidate(candidate, copy)
      end

      copied_slots << copy
    end

    # Every slot this copy created, for a caller that hands them to the members
    # listed on them.
    def copied_slots
      @copied_slots ||= []
    end

    # A list kept on a flight or template can go stale -- a ship changes hands,
    # a member's squadron row moves -- and one such entry must not stop the
    # whole team from being built. A ship that no longer fits is dropped; a
    # member who no longer fits is left off.
    private def copy_candidate(candidate, slot)
      copy = slot.public_send(@config[:candidates]).new(
        candidate.slice(:fleet_squadron_membership_id, :vehicle_id, :position)
      )
      copy.vehicle_id = nil if !copy.valid? && copy.errors.include?(:vehicle)
      copy.save if copy.valid?
    end

    private def next_position(relation)
      return 0 unless target.persisted?

      (relation.maximum(:position) || -1) + 1
    end
  end
end
