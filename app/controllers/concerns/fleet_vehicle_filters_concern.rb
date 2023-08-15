# frozen_string_literal: true

module FleetVehicleFiltersConcern
  private def vehicle_query_params
    @vehicle_query_params ||= query_params(
      :model_name_cont, :model_name_or_model_description_cont, :on_sale_eq,
      :beam_gteq, :beam_lteq, :height_gteq, :height_lteq, :length_gteq, :length_lteq,
      :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :loaner_eq,
      model_slug_in: [], manufacturer_in: [], classification_in: [], focus_in: [],
      size_in: [], price_in: [], pledge_price_in: [],
      production_status_in: [], sorts: [], member_in: []
    )
  end

  private def loaner_param
    @loaner_param ||= vehicle_query_params.delete("loaner_eq")
  end

  private def price_range
    @price_range ||= price_in.map do |prices|
      gt_price, lt_price = prices.split("-")
      gt_price = if gt_price.blank?
        0
      else
        gt_price.to_i
      end
      lt_price = if lt_price.blank?
        Float::INFINITY
      else
        lt_price.to_i
      end
      (gt_price...lt_price)
    end
  end

  private def pledge_price_range
    @pledge_price_range ||= pledge_price_in.map do |prices|
      gt_price, lt_price = prices.split("-")
      gt_price = if gt_price.blank?
        0
      else
        gt_price.to_i
      end
      lt_price = if lt_price.blank?
        Float::INFINITY
      else
        lt_price.to_i
      end
      (gt_price...lt_price)
    end
  end

  private def pledge_price_in
    pledge_price_in = vehicle_query_params.delete("pledge_price_in")
    pledge_price_in = pledge_price_in.to_s.split unless pledge_price_in.is_a?(Array)
    pledge_price_in
  end

  private def price_in
    price_in = vehicle_query_params.delete("price_in")
    price_in = price_in.to_s.split unless price_in.is_a?(Array)
    price_in
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
end
