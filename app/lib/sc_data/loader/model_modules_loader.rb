module ScData
  module Loader
    class ModelModulesLoader < ::ScData::Loader::BaseLoader
      def all
        ModelModule.where.not(sc_key: nil).find_each do |model_module|
          load_model_module(model_module)
        end
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
