# frozen_string_literal: true

module HangarVehicles
  private def loaner_included?(scope)
    if vehicle_query_params['loaner_eq'].blank?
      scope = scope.where(loaner: false)
    elsif vehicle_query_params['loaner_eq'] == 'true'
      vehicle_query_params.delete('loaner_eq')
    else
      scope = scope.where(loaner: true)
    end

    scope
  end

  private def vehicle_query_params
    @vehicle_query_params ||= query_params(
      :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :purchased_eq, :public_eq,
      :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
      :pledge_price_lteq, :loaner_eq,
      manufacturer_in: [], classification_in: [], focus_in: [],
      size_in: [], price_in: [], pledge_price_in: [],
      production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
    )
  end
end
