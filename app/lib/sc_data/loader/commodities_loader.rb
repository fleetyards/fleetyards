module ScData
  module Loader
    class CommoditiesLoader < ::ScData::Loader::BaseLoader
      def all
        loaded = load_items("commodities").filter_map { |commodity_data| one(commodity_data)&.id }

        retire_absent(Commodity, loaded)
      end

      def one(commodity_data)
        return if commodity_data["name"].blank?

        commodity = Commodity.find_by(sc_key: commodity_data["sc_key"])
        commodity ||= Commodity.find_by(name: commodity_data["name"], sc_key: nil)
        commodity ||= Commodity.new(sc_key: commodity_data["sc_key"])

        commodity.update!(update_params(commodity_data))

        # Filled in only while empty, the same way the manufacturer logo is:
        # `store_image` is curated -- an admin uploads it -- so following the
        # export unconditionally would replace their picture on every load.
        attach_icon(commodity, :store_image, commodity_data["icon"]) unless commodity.store_image.attached?

        commodity
      end

      private def update_params(commodity_data)
        {
          sc_key: commodity_data["sc_key"],
          sc_ref: commodity_data["ref"],
          name: commodity_data["name"],
          commodity_type: commodity_data["commodity_type"],
          description: commodity_data["description"],
          version: sc_version
        }
      end
    end
  end
end
