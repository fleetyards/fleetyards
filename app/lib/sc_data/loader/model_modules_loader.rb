module ScData
  module Loader
    class ModelModulesLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = []

        ModelModule.where.not(sc_key: nil).find_each do |model_module|
          loaded << model_module.id if load_model_module(model_module)
        end

        # A module this build stopped describing keeps its row -- it is created
        # by `ModulesImporter` or by an admin, never here, so a load has no
        # business deleting it -- and stops having a row for this build. That is
        # what makes it answerable whether the build ships the module at all,
        # which is the whole point of the table: without it a module only the
        # ptu build knows is offered under live as well.
        retire_absent_builds(ModelModuleBuild, :model_module_id, loaded)

        prune_builds(ModelModuleBuild)
      end

      def one(model_module)
        load_model_module(model_module)
      end

      def load_model_module(model_module)
        return if model_module.sc_key.blank?

        module_data = load_module_data(model_module.sc_key)

        # A build that stopped shipping this module's item file leaves the module
        # alone rather than crashing the load. `load_item` answers nil for a path
        # the tree does not carry and `resolve_loadout` indexes it straight away,
        # so this used to be a NoMethodError on nil -- and since the whole of
        # `BaseLoader.all` runs in one job, it took every loader after this one
        # with it. Guarded the way `ModelsLoader#load_model` guards, rather than
        # by making `resolve_loadout` tolerant: it raises on a payload carrying
        # no loadout on purpose, and that is pinned.
        #
        # The module keeps the loadout the last build gave it, which is the only
        # answer available while `ModelModule` has no build table of its own --
        # once it has one, this is where the module would be retired from the
        # build instead.
        return if module_data.blank?

        update_loadout(model_module, module_data)

        update_params = {
          production_status: "flight-ready"
        }

        update_params = update_metrics(module_data, update_params)
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

      private def update_metrics(module_data, update_params)
        update_params[:description] = module_data.dig("description") if module_data.dig("description").present?

        update_params
      end
    end
  end
end
