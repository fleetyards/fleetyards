module ScData
  module Loader
    class GameMissionsLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = load_items("game_missions").filter_map { |mission_data| one(mission_data)&.id }

        retire_absent(GameMission, loaded)
        retire_absent_builds(GameMissionBuild, :game_mission_id, loaded)

        prune_builds(GameMissionBuild)
      end

      def one(mission_data)
        return if mission_data["sc_ref"].blank?
        return if mission_data["sc_key"].blank?

        mission = GameMission.find_by(sc_ref: mission_data["sc_ref"])
        mission ||= GameMission.new(sc_ref: mission_data["sc_ref"])

        update_params = update_params(mission_data)

        # One transaction for the row, its build and the rewards. Nothing above
        # opens one -- `Loaders::ScData::AllJob` only sets the source -- so a
        # failure part way through would otherwise leave a readable build whose
        # rewards are missing or half written.
        GameMission.transaction do
          apply(mission, update_params)

          # `sc_ref` and `sc_key` identify the contract rather than describing a
          # build, so they stay on the row and are not repeated here.
          build = apply_build(mission, update_params.except(:sc_ref, :sc_key, :version))

          persist_rewards(build, mission_data["rewards"])
        end

        mission
      end

      private def update_params(mission_data)
        difficulty = mission_data["difficulty"] || {}
        rewards = Array.wrap(mission_data["rewards"])

        {
          sc_ref: mission_data["sc_ref"],
          sc_key: mission_data["sc_key"],
          name: mission_data["title"],
          description: mission_data["description"],
          kind: mission_data["kind"],
          generator_key: mission_data["generator_key"],
          debug_name: mission_data["debug_name"],
          org_ref: mission_data["org_ref"],
          org_key: mission_data["org_key"],
          org_name: mission_data["org_name"],
          org_lawful: mission_data["org_lawful"],
          # Curated this side of the tree, the way blueprint sources are: the
          # neutral list is a call we make, and made here it takes effect on the
          # next load instead of needing the build re-parsed and pushed.
          alignment: ::BlueprintSource.alignment_for(
            org_key: mission_data["org_key"], lawful: mission_data["org_lawful"]
          ),
          min_standing: mission_data["min_standing"],
          max_standing: mission_data["max_standing"],
          # The parser states it for every contract, so a blank is a tree parsed
          # before this field existed rather than a contract nobody can take.
          released: mission_data.fetch("released", true),
          difficulty_profile: difficulty["profile"],
          difficulty_mechanical_skill: difficulty["mechanical_skill"],
          difficulty_mental_load: difficulty["mental_load"],
          difficulty_risk_of_loss: difficulty["risk_of_loss"],
          difficulty_game_knowledge: difficulty["game_knowledge"],
          # Denormalised off the rewards so a "pays reputation" filter is an
          # index lookup rather than an exists check per row.
          reward_kinds: reward_kinds(rewards, mission_data["blueprint_pools"]),
          blueprint_pool_refs: Array.wrap(mission_data["blueprint_pools"]).uniq.sort,
          version: sc_version
        }
      end

      # What the mission pays, as a reader would ask it.
      #
      # "blueprint" is deliberately not a row in `game_mission_rewards`: a recipe
      # is handed out through a reward pool rather than as a contract result, and
      # the pool is what `blueprint_pool_refs` carries. But it is very much
      # something the mission gives you, and somebody filtering "what do I get"
      # should not have to know which side of the export it came from.
      #
      # Sorted so a build that only reordered its results does not read as a
      # change.
      private def reward_kinds(rewards, pools)
        kinds = rewards.filter_map { |reward| reward["kind"] }
        kinds << ::GameMissionBuild::BLUEPRINT_REWARD_KIND if Array.wrap(pools).any?

        kinds.uniq.sort
      end

      # Written against the build and rewritten wholesale on every run rather
      # than reconciled row by row. Nothing points at a reward line, so there is
      # nothing that has to keep resolving, and a contract CIG re-costs has to
      # lose the rewards it no longer pays.
      #
      # The delete lands before the insert, so this has to run inside a
      # transaction: `one` opens it.
      private def persist_rewards(build, rewards)
        rows = Array.wrap(rewards).map.with_index do |reward, position|
          {
            id: SecureRandom.uuid,
            game_mission_build_id: build.id,
            kind: reward["kind"],
            amount: reward["amount"],
            max: reward["max"],
            currency: reward["currency"],
            org_key: reward["org_key"],
            org_name: reward["org_name"],
            entity_class: reward["entity_class"],
            entity_name: reward["entity_name"],
            weight: reward["weight"],
            badge: reward["badge"],
            position:,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          }
        end

        # A build written for the first time has nothing to clear, and a full
        # load is 2,536 of them -- the sweep is for a re-load of a build that is
        # already there.
        build.rewards.delete_all unless build.previously_new_record?

        return if rows.blank?

        GameMissionReward.insert_all!(rows)

        stats[GameMissionReward.name][:created] += rows.size

        build.association(:rewards).reset
      end
    end
  end
end
