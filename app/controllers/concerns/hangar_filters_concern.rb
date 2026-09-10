# frozen_string_literal: true

module HangarFiltersConcern
  include WillItFitConcern

  private def vehicle_query_params
    @vehicle_query_params ||= params.permit(q: ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")).fetch(:q, {})
  end

  private def will_it_fit?(scope)
    will_it_fit_scope(scope, will_it_fit_carrier(vehicle_query_params.delete("will_it_fit")))
  end

  private def loaner_included?(scope)
    case vehicle_query_params.delete("loaner_eq")
    when "true"
      scope
    when "only"
      scope.where(loaner: true)
    else
      scope.where(loaner: false)
    end
  end

  private def bundled_included?(scope)
    case vehicle_query_params.delete("bundled_eq")
    when "false"
      scope.where(bundled: false)
    when "only"
      scope.where(bundled: true)
    else
      scope
    end
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
