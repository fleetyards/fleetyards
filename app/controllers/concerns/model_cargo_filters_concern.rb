# frozen_string_literal: true

module ModelCargoFiltersConcern
  # A model has a cargo grid either because its own game files describe one or
  # because a module it can carry brings one with it.
  private def with_cargo_grids(scope)
    scope.where(
      id: Model.joins(:cargo_holds_db).select(:id)
    ).or(
      scope.where(
        id: Model.joins(:module_hardpoints).select(:id)
      )
    ).distinct
  end

  private def container_fit_params
    @container_fit_params ||= params.permit(container_fit: {})[:container_fit]
  end

  private def container_fit(scope)
    return scope if container_fit_params.blank?

    container_set = container_fit_params.to_h.transform_keys(&:to_i).transform_values(&:to_i).select { |_k, v| v > 0 }
    return scope if container_set.empty?

    scope.where(id: ScData::CargoFinderSql.find_fitting_models(container_set).select(:id))
  end
end
