# frozen_string_literal: true

module HangarFiltersConcern
  include WillItFitConcern

  private def vehicle_query_params
    @vehicle_query_params ||= Vehicle.fitted_filters(
      params.permit(q: ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")).fetch(:q, {}),
      public_only: public_vehicle_list?
    )
  end

  private def public_vehicle_list?
    self.class.name.start_with?("Api::V1::Public::")
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

  # Loaner deduplication keeps one visible row per hidden_by_user state, so
  # listing both states at once would show a loaner twice; the ones lent by
  # hidden ships are only listed on their own.
  private def hidden_by_user_included?(scope)
    case vehicle_query_params.delete("hidden_by_user_eq")
    when "true"
      scope.where(hidden_by_user: false).or(scope.where(hidden_by_user: true, loaner: false))
    when "only"
      scope.where(hidden_by_user: true)
    else
      scope.where(hidden_by_user: false)
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
end
