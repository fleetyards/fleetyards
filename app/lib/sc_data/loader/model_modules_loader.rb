module ScData
  module Loader
    class ModelModulesLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = []

        discover_modules

        modules = ModelModule.where.not(sc_key: nil)
        @progress&.total = modules.count
        modules.find_each do |model_module|
          loaded << model_module.id if load_model_module(model_module)
          @progress&.advance
        end

        # A module this build stopped describing keeps its row -- a hangar or a
        # loadout may still point at it, so a load has no business deleting it
        # -- and stops having a row for this build. That is
        # what makes it answerable whether the build ships the module at all,
        # which is the whole point of the table: without it a module only the
        # ptu build knows is offered under live as well.
        retire_absent_builds(ModelModuleBuild, :model_module_id, loaded)

        prune_builds(ModelModuleBuild)
      end

      def one(model_module)
        load_model_module(model_module)
      end

      # Every part a ship's module slot takes, linked to that ship as one of its
      # modules: what the game offers, not only what the RSI store sells or an
      # admin entered. A slot is a port that takes a `Module`; the parts are
      # whatever fits it, so the Hornet's centre bay offers its ball turrets,
      # rotodome and interdiction generator beside the cargo box. Body kits fit
      # module slots as well and change only looks, so the ship page lists them
      # on their own.
      #
      # Runs against the components this build's items load wrote, so it uses
      # the loadout editor's fitting rules rather than a second copy of them.
      def discover_modules
        ::ScData::Source.with(source) do
          candidates = {}

          Model.find_each do |model|
            slots = model.hardpoints.game_files.in_build(source).includes(::LoadoutSlots::FACTS_PRELOAD)
              .select { |hardpoint| Array(hardpoint.facts.types).include?("Module") }
            next if slots.empty?

            provided = ::LoadoutSlots.ship_tags_for(model)

            slots.each do |slot|
              module_options(slot, provided, candidates).each do |component|
                link_module(model, slot, component)
              end
            end
          end
        end
      end

      private def module_options(slot, provided, candidates)
        facts = slot.facts
        types = Array(facts.types).compact_blank.sort

        candidates[types] ||= ::Component.joins(::Component.current_facts_join(source))
          .where(::Component.fact_sql(:component_type).in(types))
          .where(::Component.fact_sql(:category).not_eq("bodykit").or(::Component.fact_sql(:category).eq(nil)))
          .where.not(sc_key: nil)
          .to_a

        stock = facts.component
        # A port that takes turrets as well as modules but names no tag would
        # take every turret in the game; only a tag ties the other kinds of part
        # to this ship.
        other_kinds = Array(facts.required_tags).compact_blank.any?

        candidates[types].select do |component|
          stock_part = component.id == stock&.id
          next false unless offered_module?(component, stock: stock_part)
          next true if stock_part
          next false unless component.component_type == "Module" || other_kinds

          size = Integer(component.size, exception: false)

          !size.nil? &&
            (facts.min_size.nil? || size >= facts.min_size) &&
            (facts.max_size.nil? || size <= facts.max_size) &&
            ::LoadoutSlots.sub_type_fits?(facts, component) &&
            ::LoadoutSlots.tags_fit?(facts, component, stock, provided)
        end
      end

      # The game files keep records no player fits beside the real modules:
      # the empty bay a ship comes with (`_Base`), templates, the parent record
      # each family of modules is cloned from -- named after the slot tag it
      # carries, `RSI_Galaxy_Module` -- and stubs whose ports are all size 0,
      # left behind when CIG rebuilt a module under another key (the MPUV's
      # pods under `aegs/` beside the real ones under `argo/`). A part a ship
      # comes with is no stub, whatever its ports: the F7C Hornet Mk II's cargo
      # door holds its grid on a size 0 port.
      NOT_OFFERED_KEY = /_(base|template|temp)(_|\z)/i

      private def offered_module?(component, stock: false)
        key = component.sc_key.to_s
        return false if key.match?(NOT_OFFERED_KEY)
        return false if Array(component.tags).any? { |tag| tag.casecmp?(key) }
        return true if stock

        ports = component.hardpoints.in_build(source).to_a
        ports.empty? || ports.any? { |port| port.facts.max_size.to_i.positive? }
      end

      private def link_module(model, slot, component)
        key = item_key(component)
        model_module = ModelModule.find_by("lower(sc_key) = ?", key.downcase) ||
          adopt_store_module(model, key) ||
          create_module(component, key)

        module_hardpoint = ModuleHardpoint.find_or_initialize_by(model:, model_module:)
        module_hardpoint.slot ||= slot.sc_name
        module_hardpoint.save! if module_hardpoint.changed?
      end

      # Components keep their key lowercased; the item file keeps it as CIG
      # writes it, which is what the curated modules carry and what a name can
      # be read from.
      private def item_key(component)
        load_module_data(component.sc_key)&.dig("key").presence || component.sc_key
      end

      # A module the RSI store sells is already on the ship, under the store's
      # name and without a key: the Galaxy's "Refinery Module" is
      # `RSI_Galaxy_Module_Refinery`. It takes the key rather than getting a
      # twin, when exactly one of the ship's keyless modules names every word
      # of the key that is not the maker, the ship or "module".
      private def adopt_store_module(model, key)
        ship_words = model.name.to_s.downcase.split(/[^a-z0-9]+/)
        wanted = self.class.key_words(key).drop(1) - ship_words - %w[module mod]
        return if wanted.empty?

        matches = model.modules.where(sc_key: nil).select do |model_module|
          (wanted - model_module.name.to_s.downcase.split(/[^a-z0-9]+/)).empty?
        end
        return unless matches.one?

        apply(matches.first, {sc_key: key, update_reason: :sc_loader})
      end

      private def create_module(component, key)
        apply(ModelModule.new, {
          sc_key: key,
          name: component.name.presence || self.class.fallback_name(key),
          manufacturer: component.manufacturer,
          hidden: false,
          active: true
        })
      end

      def self.key_words(sc_key)
        sc_key.to_s.split("_").flat_map { |word| word.gsub(/(?<=[a-z])(?=[A-Z])/, " ").split }.map(&:downcase)
      end

      # What a module is called until CIG names it: its key without the
      # manufacturer code, words split -- `ARGO_MPUV_Module_1C_CargoPod` reads
      # "MPUV Module 1C Cargo Pod".
      def self.fallback_name(sc_key)
        sc_key.to_s.split("_").drop(1).map { |word| word.gsub(/(?<=[a-z])(?=[A-Z])/, " ") }.join(" ")
      end

      def load_model_module(model_module)
        return if model_module.sc_key.blank?

        module_data = load_module_data(model_module.sc_key)

        # A build that stopped shipping this module's item file writes no build
        # row for it, so `all` retires the module from that build. Returning
        # rather than resolving nil matters: the whole of `BaseLoader.all` runs
        # in one job, and a raise here takes every loader after this one with it.
        return if module_data.blank?

        # Some module items ship with no ports at all. `resolve_loadout` raises on
        # that on purpose, because for a ship it means the file is broken; for a
        # module it is an empty loadout, which retires whatever slots it had.
        if module_data["loadout"] || module_data["default_loadout"]
          update_loadout(model_module, module_data)
        else
          persist_loadout(model_module, [])
        end

        # Curated until the live game ships it, automatic afterwards.
        #
        # A ptu build saying so is not the game saying so, so this asks the
        # *default* source rather than the one being loaded -- a ptu load of a
        # module live does not have leaves whatever an admin chose alone, and a
        # live load flips it.
        #
        # Two ways live can describe it: a row already exists, or this load is
        # the live one and is about to write it. Without the second, the status
        # would lag a build behind, because `apply_build` runs after this.
        #
        # It does not go back if live later drops the module: there is nothing to
        # go back to that would not be a guess, and guessing would overwrite
        # curation. Not decidable at all before modules had builds.
        live = ::ScData::Source.default
        ships_in_live = source == live || model_module.builds.current(live).any?

        # A module still under the stand-in name its key gave it is one nobody
        # has named -- not CIG, not the store, not an admin -- and so not in
        # players' hands, live or not.
        stand_in = model_module.name == self.class.fallback_name(module_data["key"] || model_module.sc_key)
        game_name = module_data["name"].presence

        update_params = {}
        update_params[:production_status] = "flight-ready" if ships_in_live && (game_name || !stand_in)
        # The stand-in gives way once the game names the module; a name an admin
        # chose stays.
        update_params[:name] = game_name if game_name && stand_in

        update_params = update_metrics(model_module, module_data, update_params)
        # This build's slots, for the same reason the models loader asks that
        # way: a slot the build dropped keeps its row and would still be counted
        # into the module's cargo holds.
        update_params = update_cargo_holds(model_module.hardpoints.in_build(source), update_params)

        apply(model_module, update_params.merge(update_reason: :sc_loader))

        # Read off the module rather than off `update_params`: `cargo_holds`
        # comes back through the YAML coder, and `update_from_hardpoints` runs in
        # a `before_save` that can change it.
        apply_build(model_module, ModelModuleBuild.facts_from(model_module.reload))
      end

      private def load_module_data(sc_key)
        load_item("items/#{sc_key.downcase}")
      end

      private def update_metrics(model_module, module_data, update_params)
        update_params[:description] = module_data.dig("description") if module_data.dig("description").present?
        # Cleared when a build drops the beds, but not written for a module that
        # never had any.
        medical_beds = module_data["medical_beds"].presence
        update_params[:medical_beds] = medical_beds if medical_beds || model_module.read_attribute(:medical_beds)

        update_params
      end
    end
  end
end
