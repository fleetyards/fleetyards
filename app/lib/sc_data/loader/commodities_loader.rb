module ScData
  module Loader
    class CommoditiesLoader < ::ScData::Loader::BaseLoader
      def all
        parsed = load_items("commodities")
        loaded = parsed.filter_map { |commodity_data| one(commodity_data)&.id }

        link_refined_versions(parsed)

        retire_absent(Commodity, loaded)
        retire_absent_builds(CommodityBuild, :commodity_id, loaded)

        prune_builds(CommodityBuild)
      end

      def one(commodity_data)
        return if commodity_data["name"].blank?

        commodity = Commodity.find_by(sc_key: commodity_data["sc_key"])
        commodity ||= Commodity.find_by(name: commodity_data["name"], sc_key: nil)
        commodity ||= Commodity.new(sc_key: commodity_data["sc_key"])

        apply(commodity, update_params(commodity_data))
        apply_build(commodity, update_params(commodity_data).except(:sc_key, :sc_ref, :version))

        # Filled in only while empty, the same way the manufacturer logo is:
        # `store_image` is curated -- an admin uploads it -- so following the
        # export unconditionally would replace their picture on every load.
        attach_icon(commodity, :store_image, commodity_data["icon"]) unless commodity.store_image.attached?

        commodity
      end

      # Resolved after every row exists, because an ore may be read before the
      # good it refines into. Written with `update_all` rather than through the
      # record: this is the loader's column, and versioning 30 links on every
      # load would bury the handful of real edits the way the UEX sync already
      # threatens to.
      private def link_refined_versions(parsed)
        keys = parsed.filter_map { |commodity_data| commodity_data["sc_key"] }
        ids = Commodity.where(sc_key: keys).pluck(:sc_key, :id).to_h

        wanted = parsed.each_with_object({}) do |commodity_data, index|
          source = ids[commodity_data["sc_key"]]
          target = ids[commodity_data["refines_into"]]

          index[source] = target if source.present?
        end

        # One statement per distinct target rather than per row, and only where
        # the answer has moved -- a re-load of the same build writes nothing.
        #
        # `IS DISTINCT FROM` rather than `where.not`: every row starts with a
        # null here, and `refines_into_id != '<uuid>'` is null for a null column
        # rather than true, so `where.not` matches none of the rows that need
        # the write.
        wanted.group_by { |_, target| target }.each do |target, pairs|
          Commodity.where(id: pairs.map(&:first))
            .where("refines_into_id IS DISTINCT FROM ?", target)
            .update_all(refines_into_id: target, updated_at: Time.current)
        end
      end

      private def update_params(commodity_data)
        {
          sc_key: commodity_data["sc_key"],
          sc_ref: commodity_data["ref"],
          name: commodity_data["name"],
          commodity_type: commodity_data["commodity_type"],
          description: commodity_data["description"],
          counted: commodity_data["counted"] || false,
          piece_volume: commodity_data["piece_volume"],
          consumable: commodity_data["consumable"] || false,
          container_sizes: Array.wrap(commodity_data["container_sizes"]),
          version: sc_version
        }
      end
    end
  end
end
