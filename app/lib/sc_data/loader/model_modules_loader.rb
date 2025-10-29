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

        update_loadout(model_module, module_data)

        update_params = {}

        update_params = update_metrics(module_data, update_params)
        update_params = update_cargo_holds(model_module.hardpoints, update_params)

        model_module.update!(update_params.merge(audit_comment: :sc_loader))
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
