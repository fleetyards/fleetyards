# frozen_string_literal: true

module ScData
  # SQL-based cargo finder using cargo_holds and cargo_hold_container_capacities tables
  # This is the optimized version that uses database queries instead of Ruby iteration
  class CargoFinderSql
    SCU_DIMENSIONS = 1.25

    CARGO_CONTAINER_DIMENSIONS = CargoFinder::CARGO_CONTAINER_DIMENSIONS

    # Find models that can fit a specific container set using SQL
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    #   Example: { 8 => 11, 4 => 1 } means 11x 8 SCU containers + 1x 4 SCU container
    # @return [ActiveRecord::Relation] Models that can fit the container set
    def self.find_fitting_models(container_set)
      total_cargo = container_set.sum { |size, quantity| size * quantity }

      # Start with models that have enough total capacity
      query = Model.visible.active
        .where("cargo >= ?", total_cargo)
        .joins(:cargo_hold_container_capacities)
        .distinct

      # For each container size/quantity pair, ensure the model has enough capacity
      container_set.each do |container_size, required_quantity|
        # Subquery: sum of max_quantity for this container size across all holds for each model
        subquery = CargoHoldContainerCapacity
          .joins(:cargo_hold)
          .where(container_size_scu: container_size)
          .where("cargo_holds.model_id = models.id")
          .select("COALESCE(SUM(cargo_hold_container_capacities.max_quantity), 0)")

        query = query.where(
          "#{required_quantity} <= (#{subquery.to_sql})"
        )
      end

      query
    end

    # Check if a model can fit the given container set using database data
    # @param model [Model] The ship model to check
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    # @return [Boolean] True if the model can fit all containers
    def self.can_fit_containers?(model, container_set)
      return false if model.cargo_holds_db.blank?

      # Check total capacity first (quick check)
      total_required_capacity = container_set.sum { |size, quantity| size * quantity }
      return false if model.cargo < total_required_capacity

      # Check if each container type can fit in the combined holds
      container_set.all? do |container_size, required_quantity|
        total_capacity = model.cargo_hold_container_capacities
          .where(container_size_scu: container_size)
          .sum(:max_quantity)

        total_capacity >= required_quantity
      end
    end

    # Get detailed fitting information for a model
    # @param model [Model] The ship model
    # @param container_set [Hash] Container set to check
    # @return [Hash] Detailed information about fitting
    def self.fitting_details(model, container_set)
      result = {
        model_id: model.id,
        model_name: model.name,
        model_slug: model.slug,
        total_cargo: model.cargo,
        required_cargo: container_set.sum { |size, qty| size * qty },
        can_fit: true,
        holds: [],
        container_allocation: {}
      }

      container_set.each do |container_size, required_quantity|
        total_capacity = model.cargo_hold_container_capacities
          .where(container_size_scu: container_size)
          .sum(:max_quantity)

        result[:container_allocation][container_size] = {
          required: required_quantity,
          available: total_capacity,
          fits: total_capacity >= required_quantity
        }

        result[:can_fit] = false if total_capacity < required_quantity
      end

      model.cargo_holds_db.ordered.each do |hold|
        hold_info = {
          id: hold.id,
          dimensions: "#{hold.dimension_x} × #{hold.dimension_y} × #{hold.dimension_z}",
          capacity_scu: hold.capacity_scu,
          max_container_size: hold.max_container_size_scu,
          capacities: {}
        }

        hold.cargo_hold_container_capacities.each do |cap|
          next if cap.max_quantity.zero?

          hold_info[:capacities][cap.container_size_scu] = {
            max_quantity: cap.max_quantity,
            orientation: cap.best_orientation
          }
        end

        result[:holds] << hold_info
      end

      result
    end

    # Get summary statistics for all models
    # @return [Hash] Statistics about cargo capacity across all models
    def self.statistics
      {
        total_models: Model.visible.active.count,
        models_with_cargo: Model.visible.active.where("cargo > 0").count,
        models_with_cargo_holds: Model.visible.active.joins(:cargo_holds_db).distinct.count,
        total_cargo_holds: CargoHold.count,
        average_cargo_holds_per_model: CargoHold.group(:model_id).count.values.sum.to_f / CargoHold.distinct.count(:model_id),
        container_size_distribution: CargoHoldContainerCapacity
          .where("max_quantity > 0")
          .group(:container_size_scu)
          .count
      }
    end

    # Find models that can fit at least N containers of a specific size
    # @param container_size [Integer] Container size in SCU
    # @param min_quantity [Integer] Minimum quantity
    # @return [ActiveRecord::Relation] Models matching criteria
    def self.find_models_with_min_capacity(container_size, min_quantity)
      Model.visible.active
        .joins(:cargo_hold_container_capacities)
        .where(cargo_hold_container_capacities: {container_size_scu: container_size})
        .group("models.id")
        .having("SUM(cargo_hold_container_capacities.max_quantity) >= ?", min_quantity)
    end

    # Find best models for a container set (sorted by remaining capacity)
    # @param container_set [Hash] Container set
    # @param limit [Integer] Number of results to return
    # @return [Array<Hash>] Models with fitting details sorted by remaining capacity
    def self.find_best_fitting_models(container_set, limit: 10)
      models = find_fitting_models(container_set).limit(limit * 2)

      results = models.map do |model|
        details = fitting_details(model, container_set)
        next unless details[:can_fit]

        remaining_capacity = details[:total_cargo] - details[:required_cargo]
        details.merge(remaining_capacity:)
      end.compact

      results.sort_by { |r| -r[:remaining_capacity] }.take(limit)
    end
  end
end
