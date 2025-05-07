# frozen_string_literal: true

module HangarFiltersConcern
  private def vehicle_query_params
    @vehicle_query_params ||= query_params(
      :search_cont, :name_cont, :model_name_or_model_description_cont, :on_sale_eq,
      :public_eq, :length_gteq, :length_lteq, :beam_gteq, :beam_lteq, :height_gteq, :height_lteq,
      :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :loaner_eq, :bought_via_eq,
      :will_it_fit, :with_cargo,
      manufacturer_in: [], classification_in: [], focus_in: [],
      size_in: [], price_in: [], pledge_price_in: [],
      production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
    )
  end

  private def will_it_fit?(scope)
    slug = vehicle_query_params.delete("will_it_fit")
    parent = Model.visible.active.where(slug:).or(Model.where(rsi_slug: slug)).first

    return scope if parent.blank? || parent.docks.blank?

    vehicle_dock = parent.docks.where(dock_type: %i[vehiclepad garage]).order(length: :desc).first
    ship_dock = parent.docks.where(dock_type: %i[landingpad hangar]).order(length: :desc).first

    dock_metrics = extract_dock_metrics(ship_dock, vehicle_dock)

    if ship_dock && vehicle_dock
      will_it_fit_ship_or_vehicle_dock?(scope, dock_metrics)
    elsif ship_dock
      will_it_fit_ship_dock?(scope, dock_metrics)
    else
      will_it_fit_vehicle_dock?(scope, dock_metrics)
    end
  end

  private def extract_dock_metrics(ship_dock, vehicle_dock)
    {
      ship_length: (ship_dock&.length || 0) - 2.0,
      ship_beam: (ship_dock&.beam || 0) - 2.0,
      ship_height: (ship_dock&.height || 0) - 1.0,
      vehicle_length: (vehicle_dock&.length || 0) - 1.0,
      vehicle_beam: (vehicle_dock&.beam || 0) - 1.0,
      vehicle_height: (vehicle_dock&.height || 0) - 0.5
    }
  end

  private def will_it_fit_ship_or_vehicle_dock?(scope, dock_metrics)
    scope.where(
      models: {
        ground: [false, nil],
        length: ..dock_metrics[:ship_length],
        beam: ..dock_metrics[:ship_beam],
        height: ..dock_metrics[:ship_height]
      }
    ).or(
      models: {
        ground: true,
        length: ..dock_metrics[:vehicle_length],
        beam: ..dock_metrics[:vehicle_beam],
        height: ..dock_metrics[:vehicle_height]
      }
    )
  end

  private def will_it_fit_ship_dock?(scope, dock_metrics)
    scope.where(
      models: {
        ground: [false, nil],
        length: ..dock_metrics[:ship_length],
        beam: ..dock_metrics[:ship_beam],
        height: ..dock_metrics[:ship_height]
      }
    )
  end

  private def will_it_fit_vehicle_dock?(scope, dock_metrics)
    scope.where(
      models: {
        ground: true,
        length: ..dock_metrics[:vehicle_length],
        beam: ..dock_metrics[:vehicle_beam],
        height: ..dock_metrics[:vehicle_height]
      }
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
