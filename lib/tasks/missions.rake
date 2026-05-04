# frozen_string_literal: true

module MissionBuilderExamples
  EXAMPLES = [
    {
      title: "Fighter Sweep",
      category: "ship_combat",
      description: "Light fighter patrol clearing pirate activity from a contested system. Pure ship combat, fast in/out.",
      teams: [
        {
          title: "Strike Element",
          description: "Forward air-to-air engagement.",
          slots: ["Wing Lead", "Wing 2", "Wing 3", "Wing 4"],
          ships: [
            {model: "Gladius"},
            {model: "Arrow"},
            {model: "Sabre"}
          ]
        },
        {
          title: "Heavy Support",
          description: "Anti-fighter platform providing fire support.",
          slots: ["Mission Commander"],
          ships: [{model: "Hammerhead"}]
        }
      ]
    },
    {
      title: "Ground Assault",
      category: "ground_combat",
      description: "Surface objective takedown. Ground troops assault a fortified outpost while air cover suppresses defenders.",
      teams: [
        {
          title: "Boots on the Ground",
          description: "Marine team driving the assault.",
          slots: ["Squad Leader", "Marine 1", "Marine 2", "Marine 3"],
          ships: [{model: "Cyclone"}]
        },
        {
          title: "Air Cover",
          description: "Suppression and overwatch.",
          slots: ["Flight Lead"],
          ships: [
            {model: "Hurricane"},
            {model: "Vanguard Sentinel"}
          ]
        }
      ]
    },
    {
      title: "Combined Combat Operation",
      category: "combined_combat",
      description: "Coordinated naval + ground op. Capital-class strike package with ground insertion.",
      teams: [
        {
          title: "Naval Strike Group",
          description: "Capital, escort, and CAP elements.",
          slots: ["Group Commander", "Naval Liaison"],
          ships: [
            {model: "Hammerhead"},
            {model: "Vanguard Sentinel"},
            {model: "Gladius"}
          ]
        },
        {
          title: "Marine Element",
          description: "Surface objective team.",
          slots: ["Marine Commander", "Boarding Lead"],
          ships: [
            {model: "Cutlass Black"},
            {model: "Cyclone"}
          ]
        },
        {
          title: "Logistics",
          description: "Supply, refuel, repair.",
          slots: ["Logistics Lead"],
          ships: [
            {classification: "transport", min_size: "large"}
          ]
        }
      ]
    },
    {
      title: "Mining Operation",
      category: "mining",
      description: "Ore extraction run with refining and hauling. Includes light escort against pirate interest.",
      teams: [
        {
          title: "Mining Crew",
          description: "Primary extraction.",
          slots: ["Operation Lead"],
          ships: [
            {model: "MOLE"},
            {model: "Prospector"},
            {model: "Prospector"}
          ]
        },
        {
          title: "Hauling",
          description: "Move refined ore to market.",
          slots: ["Logistics Lead"],
          ships: [
            {model: "Hull C"},
            {model: "Caterpillar"}
          ]
        },
        {
          title: "Escort",
          description: "Pirate response.",
          slots: ["Escort Lead"],
          ships: [
            {classification: "combat", min_size: "medium"}
          ]
        }
      ]
    },
    {
      title: "Salvage Operation",
      category: "salvage",
      description: "Recover wreckage from a recent fleet engagement. Strip hulls, haul materials, defend the site.",
      teams: [
        {
          title: "Salvage Crew",
          description: "Hull stripping and material processing.",
          slots: ["Salvage Director"],
          ships: [
            {model: "Reclaimer"},
            {model: "Vulture"},
            {model: "Vulture"}
          ]
        },
        {
          title: "Site Security",
          description: "Defensive posture against scavengers.",
          slots: ["Security Lead"],
          ships: [
            {model: "Vanguard Sentinel"},
            {model: "Hammerhead"}
          ]
        }
      ]
    },
    {
      title: "Cargo Hauling",
      category: "cargo_hauling",
      description: "Bulk freight run between trade hubs. Convoy formation with escort element.",
      teams: [
        {
          title: "Convoy",
          description: "Primary haulage.",
          slots: ["Convoy Lead"],
          ships: [
            {model: "Hull C"},
            {model: "Caterpillar"},
            {model: "Hull A"}
          ]
        },
        {
          title: "Escort",
          description: "Pirate intercept response.",
          slots: ["Escort Lead", "Escort Wing"],
          ships: [
            {model: "Vanguard Sentinel"},
            {classification: "combat", min_size: "medium"}
          ]
        }
      ]
    }
  ].freeze

  module_function

  def call(fleet, creator)
    EXAMPLES.each { |spec| build_mission(fleet, creator, spec) }
  end

  def build_mission(fleet, creator, spec)
    if fleet.missions.exists?(["LOWER(title) = ?", spec[:title].downcase])
      puts "  - skipping (exists): #{spec[:title]}"
      return
    end

    Mission.transaction do
      mission = fleet.missions.create!(
        title: spec[:title],
        description: spec[:description],
        category: spec[:category] || "other",
        created_by: creator
      )

      spec[:teams].each_with_index do |team_spec, team_idx|
        team = mission.mission_teams.create!(
          title: team_spec[:title],
          description: team_spec[:description],
          position: team_idx
        )

        team_spec[:slots].each_with_index do |slot_title, slot_idx|
          team.mission_slots.create!(title: slot_title, position: slot_idx)
        end

        team_spec[:ships].each_with_index do |ship_spec, ship_idx|
          ship = build_ship(team, ship_spec, ship_idx)
          next unless ship

          materialize_seats(ship)
        end
      end

      puts "  + #{spec[:title]} — #{mission.mission_teams.count} teams"
    end
  end

  def build_ship(team, spec, position)
    if spec[:model]
      model = Model.where("LOWER(name) = ?", spec[:model].downcase).where(in_game: true).first
      unless model
        puts "    ! ship skipped (model not in_game or missing): #{spec[:model]}"
        return nil
      end
      team.mission_ships.create!(model_id: model.id, position: position)
    else
      team.mission_ships.create!(
        classification: spec[:classification],
        focus: spec[:focus],
        min_size: spec[:min_size],
        max_size: spec[:max_size],
        min_crew: spec[:min_crew],
        min_cargo: spec[:min_cargo],
        position: position
      )
    end
  end

  def materialize_seats(ship)
    return unless ship.model_id

    ship.model.model_positions.order(:position).each_with_index do |mp, idx|
      ship.mission_slots.create!(
        title: mp.name,
        model_position_id: mp.id,
        position: idx
      )
    end
  end
end

namespace :missions do
  desc "Seed example mission templates for a fleet (FLEET_FID env var, defaults to first fleet)"
  task seed_examples: :environment do
    fleet = ENV["FLEET_FID"] ? Fleet.find_by!(fid: ENV["FLEET_FID"]) : Fleet.first
    abort "No fleet found. Pass FLEET_FID=... to target a specific fleet." unless fleet

    creator = fleet.fleet_memberships.where(aasm_state: "accepted").first&.user || User.first
    abort "No user found." unless creator

    puts "Seeding example missions in fleet #{fleet.fid} (created by @#{creator.username})..."
    MissionBuilderExamples.call(fleet, creator)
    puts "Done."
  end
end
