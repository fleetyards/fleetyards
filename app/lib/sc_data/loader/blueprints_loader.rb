module ScData
  module Loader
    class BlueprintsLoader < ::ScData::Loader::BaseLoader
      # Listed inside a method rather than resolved here: naming the models in
      # a constant evaluated with this class body would load them before the
      # loader itself is defined.
      def self.cost_models
        {
          slots: ::BlueprintCostSlot,
          options: ::BlueprintCostOption,
          modifiers: ::BlueprintCostModifier
        }
      end

      # Where each blueprint can be obtained, keyed by the blueprint's ref.
      # Built once per run by inverting the pools the contracts parser wrote:
      # a pool names its blueprints, and the page asks the other way round.
      #
      # Empty when the tree carries no pools at all -- an environment parsed
      # before the contracts parser existed -- and a blueprint with no entry
      # simply loads with no sources, which is also the honest answer for the
      # 875 that appear in no pool.
      def sources_by_blueprint
        @sources_by_blueprint ||= load_items("blueprint_pools").each_with_object(
          Hash.new { |all, ref| all[ref] = [] }
        ) do |pool, index|
          entries = Array.wrap(pool["sources"])

          Array.wrap(pool["blueprints"]).each do |blueprint|
            ref = blueprint["ref"]

            next if ref.blank?

            entries.each { |entry| index[ref] << pool_source(pool, blueprint, entry) }
          end
        end
      end

      private def pool_source(pool, blueprint, entry)
        {
          kind: entry["kind"],
          pool_sc_ref: pool["ref"],
          pool_key: pool["key"],
          pool_group: pool["group"],
          weight: blueprint["weight"],
          org_ref: entry["org_ref"],
          org_name: entry["org_name"],
          source_key: entry["generator_key"] || entry["scenario_key"],
          mission_name: entry["mission_name"],
          min_standing: entry["min_standing"],
          max_standing: entry["max_standing"],
          min_points: entry["min_points"]
        }
      end

      def all
        loaded = load_items("blueprints").filter_map { |blueprint_data| one(blueprint_data)&.id }

        retire_absent(Blueprint, loaded)
        retire_absent_builds(BlueprintBuild, :blueprint_id, loaded)

        prune_builds(BlueprintBuild)
      end

      def one(blueprint_data)
        return if blueprint_data["ref"].blank?
        return if blueprint_data["key"].blank?

        blueprint = Blueprint.find_by(sc_ref: blueprint_data["ref"])
        blueprint ||= Blueprint.new(sc_ref: blueprint_data["ref"])

        update_params = update_params(blueprint_data)

        # One transaction for the row, its build and the recipe. Nothing above
        # opens one -- `Loaders::ScData::AllJob` only sets the source -- so a
        # failure part way through would otherwise leave a readable build whose
        # recipe is missing or half written.
        Blueprint.transaction do
          apply(blueprint, update_params)

          # `sc_ref` and `sc_key` identify the recipe rather than describing a
          # build, so they stay on the row and are not repeated here.
          build = apply_build(blueprint, update_params.except(:sc_ref, :sc_key, :version))

          persist_costs(build, blueprint_data["slots"])
          persist_sources(build, sources_by_blueprint[blueprint_data["ref"]])
        end

        blueprint
      end

      private def update_params(blueprint_data)
        output = blueprint_data["output"] || {}
        craftable = craftable(output)

        {
          sc_ref: blueprint_data["ref"],
          sc_key: blueprint_data["key"],
          # The thing the recipe makes is what names it. The entity's own name
          # answers only where that link resolves to nothing -- four mission
          # carryables are in no catalogue at all and would load nameless.
          name: craftable&.name.presence || output["name"],
          craftable:,
          category_ref: blueprint_data["category_ref"],
          craft_time: blueprint_data["craft_time"],
          slot_count: blueprint_data["slot_count"],
          version: sc_version
        }
      end

      # A ship part and a piece of personal gear are found by the ref the
      # blueprint names. A commodity is not: `Commodity#sc_ref` comes from the
      # crate entity and is null for 100 of the 232 rows, so the parser resolved
      # the resource to its `@items_commodities_*` key and the join goes through
      # `sc_key`.
      private def craftable(output)
        case output["kind"]
        when "Component" then Component.find_by(sc_ref: output["ref"])
        when "Equipment" then Equipment.find_by(sc_ref: output["ref"])
        when "Commodity" then commodity(output["commodity_key"])
        end
      end

      private def commodity(key)
        return if key.blank?

        commodities[key]
      end

      private def commodities
        @commodities ||= Hash.new { |cache, key| cache[key] = Commodity.find_by(sc_key: key) }
      end

      # Written against the build, so live and ptu each keep their own recipe,
      # and rewritten wholesale on every run rather than reconciled row by row.
      # Nothing points at a cost line -- no ledger entry, no loadout -- so there
      # is nothing that has to keep resolving, and a recipe CIG rewrites has to
      # lose the slots it no longer has.
      #
      # The delete lands before the three inserts, so this has to run inside a
      # transaction: `one` opens it.
      #
      # Written with `insert_all!` against generated ids: a full load is 4,289
      # slots, 4,289 options and 6,524 modifiers, and taking those through
      # ActiveRecord one at a time costs more than the rest of the loader put
      # together. The ids are generated here rather than by the column default
      # so the three levels can be built in one pass.
      private def persist_costs(build, slots)
        rows = cost_rows(build, Array.wrap(slots))

        # A build written for the first time has nothing to clear, and a full
        # load is 1,607 of them -- the sweep is for a re-load of a build that
        # is already there.
        build.cost_slots.delete_all unless build.previously_new_record?

        rows.each do |model, written|
          next if written.blank?

          model.insert_all!(written)

          stats[model.name][:created] += written.size
        end

        build.association(:cost_slots).reset
      end

      # Rewritten with the build, the way the recipe is. Deduplicated first:
      # a pool is named by every difficulty of every mission that hands it out,
      # so the same org and mission arrive several times over and the page
      # would list one line per repetition.
      private def persist_sources(build, sources)
        rows = Array.wrap(sources).uniq.map.with_index do |source, position|
          source.merge(
            id: SecureRandom.uuid,
            blueprint_build_id: build.id,
            position:,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          )
        end

        build.sources.delete_all unless build.previously_new_record?

        return if rows.blank?

        BlueprintSource.insert_all!(rows)

        stats[BlueprintSource.name][:created] += rows.size

        build.association(:sources).reset
      end

      private def cost_rows(build, slots)
        now = Time.zone.now
        models = self.class.cost_models
        rows = models.each_value.to_h { |model| [model, []] }

        slots.each do |slot|
          slot_id = SecureRandom.uuid

          rows[models[:slots]] << {
            id: slot_id,
            blueprint_build_id: build.id,
            position: slot["position"],
            sc_key: slot["key"],
            name: slot["name"],
            created_at: now,
            updated_at: now
          }

          Array.wrap(slot["options"]).each do |option|
            rows[models[:options]] << {
              id: SecureRandom.uuid,
              blueprint_cost_slot_id: slot_id,
              commodity_id: commodity(option["commodity_key"])&.id,
              commodity_key: option["commodity_key"],
              cost_type: option["cost_type"],
              quantity: option["quantity"],
              min_quality: option["min_quality"],
              position: option["position"],
              created_at: now,
              updated_at: now
            }
          end

          Array.wrap(slot["modifiers"]).each do |modifier|
            rows[models[:modifiers]] << {
              id: SecureRandom.uuid,
              blueprint_cost_slot_id: slot_id,
              property_ref: modifier["property_ref"],
              property_key: modifier["property_key"],
              name: modifier["name"],
              unit_format: modifier["unit_format"],
              ramp: modifier["ramp"],
              start_quality: modifier["start_quality"],
              end_quality: modifier["end_quality"],
              modifier_at_start: modifier["modifier_at_start"],
              modifier_at_end: modifier["modifier_at_end"],
              position: modifier["position"],
              created_at: now,
              updated_at: now
            }
          end
        end

        rows
      end
    end
  end
end
