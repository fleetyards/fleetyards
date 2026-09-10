# frozen_string_literal: true

module HangarFiltersConcern
  private def vehicle_query_params
    @vehicle_query_params ||= params.permit(q: ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")).fetch(:q, {})
  end

  private def will_it_fit?(scope)
    slug = vehicle_query_params.delete("will_it_fit")
    parent = Model.visible.active.where(slug:).or(Model.where(rsi_slug: slug)).or(Model.where(legacy_slug: slug)).first

    return scope if parent.blank? || parent.docks.blank?

    # Only measured docks: the metrics below subtract clearance from a missing
    # length, which made an unmeasured dock exclude everything.
    vehicle_dock = parent.docks.where(dock_type: %i[vehiclepad garage]).select(&:measured?).max_by(&:length)
    ship_dock = parent.docks.where(dock_type: %i[landingpad hangar]).select(&:measured?).max_by(&:length)

    return scope if ship_dock.blank? && vehicle_dock.blank?

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

  # Both sides are built from `scope`, because `or` takes a relation of the same
  # class and refuses a Hash outright -- which is what this used to hand it, so a
  # carrier holding a dock of each kind answered with a 500 rather than a list.
  private def will_it_fit_ship_or_vehicle_dock?(scope, dock_metrics)
    will_it_fit_ship_dock?(scope, dock_metrics)
      .or(will_it_fit_vehicle_dock?(scope, dock_metrics))
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
