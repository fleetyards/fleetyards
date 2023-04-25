# frozen_string_literal: true

module HangarFiltersConcern
  private def vehicle_query_params
    @vehicle_query_params ||= query_params(
      :search_cont, :name_cont, :model_name_or_model_description_cont, :on_sale_eq,
      :public_eq, :length_gteq, :length_lteq, :price_gteq, :price_lteq,
      :pledge_price_gteq, :pledge_price_lteq, :loaner_eq, :bought_via_eq,
      manufacturer_in: [], classification_in: [], focus_in: [],
      size_in: [], price_in: [], pledge_price_in: [],
      production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
    )
  end

  private def loaner_included?(scope)
    if vehicle_query_params["loaner_eq"].blank?
      scope = scope.where(loaner: false)
    elsif vehicle_query_params["loaner_eq"] == "true"
      vehicle_query_params.delete("loaner_eq")
    else
      scope = scope.where(loaner: true)
    end

    scope
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
end
