# frozen_string_literal: true

module FleetVehicleFiltersConcern
  private def vehicle_query_params
    @vehicle_query_params ||= params.permit(q: [
      :model_name_cont, :model_name_or_model_description_cont, :on_sale_eq,
      :beam_gteq, :beam_lteq, :height_gteq, :height_lteq, :length_gteq, :length_lteq, :cargo_gteq, :cargo_lteq,
      :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :loaner_eq, :stealth_eq, :s, :sorts,
      model_slug_in: [], manufacturer_in: [], classification_in: [], classification_not_in: [], focus_in: [], with_landing_services: [],
      size_in: [], price_in: [], pledge_price_in: [],
      production_status_in: [], sorts: [], member_in: [], squadron_slug_in: []
    ]).fetch(:q, {}).then { |query| Vehicle.fitted_filters(query, public_only: true) }
  end

  private def loaner_param
    @loaner_param ||= vehicle_query_params.delete("loaner_eq")
  end

  private def loaner_included?
    return false if loaner_param.blank?

    return true if loaner_param == "only"

    [false, true]
  end

  private def for_members
    return if vehicle_query_params[:member_in].blank?

    @for_members ||= User.where(username: vehicle_query_params[:member_in]).pluck(:id)
  end

  # The ships a squadron filter admits: what each member of the named
  # squadrons gives them, as a subquery of vehicle ids. Taken off the fleet
  # rather than the slugs alone, so one fleet's filter cannot reach another's
  # squadron. Callers apply it to the fleet's own ships, so a squadron never
  # sees a ship the fleet does not.
  #
  # A subquery matching nothing when the named squadrons hold nobody, which is
  # what makes the filter answer "no ships" rather than silently widening to
  # the whole fleet.
  #
  # The param is deleted so ransack never sees it, which is why the answer is
  # memoised -- `nil` included. Asked again, the params alone would say that no
  # squadron was named and the second caller would count the whole fleet.
  private def for_squadron_vehicles(fleet)
    return @for_squadron_vehicles if defined?(@for_squadron_vehicles)

    slugs = vehicle_query_params.delete("squadron_slug_in")

    @for_squadron_vehicles = if slugs.present?
      ::FleetSquadron.vehicle_ids_for(
        fleet_id: fleet.id,
        squadron_ids: fleet.fleet_squadrons.where(slug: slugs).select(:id)
      )
    end
  end

  # The ships behind a fleet's filtered vehicles, in the order `sorts` asks for.
  #
  # Plucked from the fleet's own vehicles, so the ids are already scoped, and a
  # plain lookup needs no DISTINCT that would forbid ordering by a join. The
  # count is taken over the same filtered vehicles, so it matches the "3x" the
  # model-counts endpoint shows on each row.
  #
  # Ransack drops any order it is handed, so the count is spliced into the order
  # afterwards, at the place it held among the sorts. Ransack orders by one
  # expression per sort, which is what lets the model sorts in front of it be
  # counted off. When the count is the only sort, the name breaks a tie.
  private def grouped_models(query, sorts)
    sorts = Array(sorts)

    models = Model.where(id: query.result.pluck(:model_id))
      .includes(:loadout_stats)
      .ransack(sorts: FleetVehicle.model_sorts(sorts))
      .result

    count_at = sorts.index { |sort| FleetVehicle.count_sort?(sort) }
    return models if count_at.nil?

    counts = Vehicle.where(id: query.result(distinct: true).reorder(nil).select(:id))
      .group(:model_id)
      .select(:model_id, "COUNT(*) AS vehicles_count")

    direction = sorts[count_at].split.last
    count_order = Arel::Table.new(:fleet_counts)[:vehicles_count].public_send(direction)
    leading = sorts.first(count_at).count { |sort| sort.start_with?("model_") }
    orders = models.order_values

    models
      .joins("INNER JOIN (#{counts.to_sql}) fleet_counts ON fleet_counts.model_id = models.id")
      .reorder(*orders.first(leading), count_order, *orders.drop(leading))
  end
end
