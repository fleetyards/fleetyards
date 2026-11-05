module ScData
  module Loader
    class FactionsLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = load_items("factions").filter_map { |faction_data| one(faction_data)&.id }

        retire_absent(Faction, loaded)
        retire_absent_builds(FactionBuild, :faction_id, loaded)

        prune_builds(FactionBuild)
      end

      def one(faction_data)
        return if faction_data["sc_ref"].blank?
        return if faction_data["sc_key"].blank?

        # By key as well: the export is free to reissue a GUID, and a second row
        # for the same key would fail its uniqueness check and abort the load.
        faction = Faction.find_by(sc_ref: faction_data["sc_ref"])
        faction ||= Faction.find_by(sc_key: faction_data["sc_key"])
        faction ||= Faction.new

        Faction.transaction do
          apply(faction, {
            sc_ref: faction_data["sc_ref"],
            sc_key: faction_data["sc_key"],
            name: faction_data["name"],
            version: sc_version
          })

          build = apply_build(faction, build_params(faction_data))

          persist_ladders(build, faction_data["ladders"])
        end

        # On the shared row, so only the environment readers get by default
        # writes it: a ptu load must not hand live readers ptu art.
        attach_icon(faction, :logo, faction_data["icon"]) if default_environment?

        faction
      end

      private def build_params(faction_data)
        {
          name: faction_data["name"],
          description: faction_data["description"],
          lawful: faction_data["lawful"],
          alignment: ::BlueprintSource.alignment_for(
            org_key: faction_data["sc_key"], lawful: faction_data["lawful"]
          ),
          headquarters: faction_data["headquarters"],
          founded: faction_data["founded"],
          leadership: faction_data["leadership"],
          area: faction_data["area"],
          focus: faction_data["focus"]
        }
      end

      # Rewritten wholesale, like a mission's rewards: nothing points at a
      # ladder, and a build that drops one has to lose it.
      private def persist_ladders(build, ladders)
        now = Time.zone.now

        rows = Array.wrap(ladders).map.with_index do |ladder, position|
          {
            id: SecureRandom.uuid,
            faction_build_id: build.id,
            key: ladder["key"],
            name: ladder["name"],
            ceiling: ladder["ceiling"],
            ranks: ladder["ranks"],
            position:,
            created_at: now,
            updated_at: now
          }
        end

        build.ladders.delete_all unless build.previously_new_record?

        return if rows.blank?

        FactionLadder.insert_all!(rows)

        stats[FactionLadder.name][:created] += rows.size

        build.association(:ladders).reset
      end
    end
  end
end
