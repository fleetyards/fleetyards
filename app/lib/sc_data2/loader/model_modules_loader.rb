module ScData2
  module Loader
    class ModelModulesLoader < ::ScData2::Loader::BaseLoader
      def run
        ModelModule.where.not(sc_key: nil).find_each do |model_module|
          load_model_module(model_module)
        end
      end

      def run_single(model_module)
        load_model_module(model_module)
      end

      def load_model_module(model_module)
        return if model_module.sc_key.blank?

        module_data = load_module_data(model_module.sc_key)

        loadout = module_data.dig("loadout")
        default_loadout = module_data.dig("default_loadout")

        update_loadout(model_module, loadout, default_loadout)

        update_params = {}

        update_params = update_cargo_holds(model_module.hardpoints, update_params)

        model_module.update!(update_params.merge(audit_comment: :sc_loader))
      end

      private def load_module_data(sc_key)
        load_item("items/#{sc_key.downcase}")
      end
    end
  end
end
