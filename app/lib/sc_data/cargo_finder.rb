# frozen_string_literal: true

module ScData
  class CargoFinder
    SCU_DIMENSIONS = 1.25

    CARGO_CONTAINER_DIMENSIONS = [
      {
        size: 32,
        dimensions: {
          x: 8 * SCU_DIMENSIONS,
          y: 2 * SCU_DIMENSIONS,
          z: 2 * SCU_DIMENSIONS
        }
      },
      {
        size: 24,
        dimensions: {
          x: 6 * SCU_DIMENSIONS,
          y: 2 * SCU_DIMENSIONS,
          z: 2 * SCU_DIMENSIONS
        }
      },
      {
        size: 16,
        dimensions: {
          x: 4 * SCU_DIMENSIONS,
          y: 2 * SCU_DIMENSIONS,
          z: 2 * SCU_DIMENSIONS
        }
      },
      {
        size: 8,
        dimensions: {
          x: 2 * SCU_DIMENSIONS,
          y: 2 * SCU_DIMENSIONS,
          z: 2 * SCU_DIMENSIONS
        }
      },
      {
        size: 4,
        dimensions: {
          x: 2 * SCU_DIMENSIONS,
          y: 2 * SCU_DIMENSIONS,
          z: 1 * SCU_DIMENSIONS
        }
      },
      {
        size: 2,
        dimensions: {
          x: 2 * SCU_DIMENSIONS,
          y: 1 * SCU_DIMENSIONS,
          z: 1 * SCU_DIMENSIONS
        }
      },
      {
        size: 1,
        dimensions: {
          x: 1 * SCU_DIMENSIONS,
          y: 1 * SCU_DIMENSIONS,
          z: 1 * SCU_DIMENSIONS
        }
      }
    ].freeze

    # Find models that can fit a specific container set
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    #   Example: { 8 => 11, 4 => 1 } means 11x 8 SCU containers + 1x 4 SCU container
    # @return [ActiveRecord::Relation] Models that can fit the container set
    def self.find_fitting_models(container_set)
      total_cargo = container_set.sum { |size, quantity| size * quantity }

      # Pre-filter models by total cargo capacity
      models = Model.visible.active.where("cargo >= ?", total_cargo)

      # Further filter by checking if cargo holds can accommodate the containers
      models.select do |model|
        can_fit_containers?(model, container_set)
      end
    end

    # Check if a model can fit the given container set
    # @param model [Model] The ship model to check
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    # @return [Boolean] True if the model can fit all containers
    def self.can_fit_containers?(model, container_set)
      return false if model.cargo_holds.blank?

      # Check total capacity first (quick check)
      total_required_capacity = container_set.sum { |size, quantity| size * quantity }
      return false if model.cargo < total_required_capacity

      # Try to pack all containers into the cargo holds
      can_pack_containers?(model.cargo_holds, container_set)
    end

    # Attempt to pack all containers into available cargo holds
    # Uses a greedy algorithm to try to fit containers
    # @param cargo_holds [Array<Hash>] Array of cargo hold data
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    # @return [Boolean] True if all containers can be packed
    def self.can_pack_containers?(cargo_holds, container_set)
      # Create a list of all individual containers sorted by size (largest first)
      containers_to_pack = []
      container_set.each do |size, quantity|
        quantity.times { containers_to_pack << size }
      end
      containers_to_pack.sort!.reverse!

      # Initialize state for each hold with max containers it can fit for each size
      holds_state = cargo_holds.map do |hold|
        {
          original: hold,
          max_containers_by_size: calculate_max_containers_by_size(hold),
          packed_containers: Hash.new(0)
        }
      end

      # Try to pack each container
      containers_to_pack.each do |container_size|
        packed = false

        # Try to fit this container in any hold that can still accommodate it
        holds_state.each do |hold_state|
          hold = hold_state[:original]
          max_allowed = hold_state[:max_containers_by_size][container_size] || 0
          already_packed = hold_state[:packed_containers][container_size] || 0

          # Check if this container can fit in this hold
          if already_packed < max_allowed &&
              can_hold_fit_container?(hold, container_size) &&
              container_fits_physically?(hold, container_size)

            # Pack the container
            hold_state[:packed_containers][container_size] += 1
            packed = true
            break
          end
        end

        # If we couldn't pack this container anywhere, the set doesn't fit
        return false unless packed
      end

      # All containers were successfully packed
      true
    end

    # Calculate the maximum number of containers of each size that can fit in a hold
    # based on physical dimensions
    # @param hold [Hash] Cargo hold data
    # @return [Hash] Hash mapping container size to max quantity
    def self.calculate_max_containers_by_size(hold)
      return {} if hold["dimensions"].blank?

      hold_dims = hold["dimensions"]
      max_containers = {}

      CARGO_CONTAINER_DIMENSIONS.each do |container_def|
        container_size = container_def[:size]
        container_dims = container_def[:dimensions]

        # Try both orientations (normal and rotated 90 degrees around Z-axis)
        orientations = [
          {x: container_dims[:x], y: container_dims[:y], z: container_dims[:z]},
          {x: container_dims[:y], y: container_dims[:x], z: container_dims[:z]}
        ]

        max_count = 0

        orientations.each do |orientation|
          # Check if container fits in this orientation
          next unless orientation[:x] <= hold_dims["x"] &&
            orientation[:y] <= hold_dims["y"] &&
            orientation[:z] <= hold_dims["z"]

          # Calculate how many containers fit in each dimension
          count_x = (hold_dims["x"] / orientation[:x]).floor
          count_y = (hold_dims["y"] / orientation[:y]).floor
          count_z = (hold_dims["z"] / orientation[:z]).floor

          # Total containers that fit in this orientation
          total = count_x * count_y * count_z

          max_count = [max_count, total].max
        end

        max_containers[container_size] = max_count
      end

      max_containers
    end

    # Check if a specific cargo hold can fit a container of given size
    # @param hold [Hash] Cargo hold data
    # @param container_size [Integer] Size of container in SCU
    # @return [Boolean] True if the hold can fit the container
    def self.can_hold_fit_container?(hold, container_size)
      return false if hold.blank?
      return false if hold["max_container_size"].blank?

      max_size = hold["max_container_size"]["size"] || 0
      max_size >= container_size
    end

    # Get container dimensions for a given size
    # @param size [Integer] Container size in SCU
    # @return [Hash, nil] Container dimensions or nil if not found
    def self.container_dimensions(size)
      CARGO_CONTAINER_DIMENSIONS.find { |c| c[:size] == size }
    end

    # Check if a container physically fits in a cargo hold (dimension check)
    # Containers can only be rotated horizontally (around Z-axis), not flipped or placed on sides
    # @param hold [Hash] Cargo hold data with dimensions
    # @param container_size [Integer] Container size in SCU
    # @return [Boolean] True if container physically fits
    def self.container_fits_physically?(hold, container_size)
      container = container_dimensions(container_size)
      return false if container.blank? || hold["dimensions"].blank?

      hold_dims = hold["dimensions"]
      container_dims = container[:dimensions]

      # Containers can only be rotated horizontally (Z stays as height)
      # So we only swap X and Y, Z must remain vertical
      orientations = [
        # Normal orientation
        {x: container_dims[:x], y: container_dims[:y], z: container_dims[:z]},
        # Rotated 90 degrees around Z-axis
        {x: container_dims[:y], y: container_dims[:x], z: container_dims[:z]}
      ]

      orientations.any? do |orientation|
        orientation[:x] <= hold_dims["x"] &&
          orientation[:y] <= hold_dims["y"] &&
          orientation[:z] <= hold_dims["z"]
      end
    end

    # Advanced fitting check that considers physical dimensions
    # @param model [Model] The ship model to check
    # @param container_set [Hash] Hash with container sizes as keys and quantities as values
    # @return [Boolean] True if the model can physically fit all containers
    def self.can_fit_containers_advanced?(model, container_set)
      return false if model.cargo_holds.blank?

      total_required_capacity = container_set.sum { |size, quantity| size * quantity }
      return false if model.cargo < total_required_capacity

      # Check if each container type can fit in at least one hold
      container_set.all? do |container_size, _quantity|
        model.cargo_holds.any? do |hold|
          container_fits_physically?(hold, container_size)
        end
      end
    end
  end
end

# Example usage:
# container_set = { 8 => 11, 4 => 1 }  # 11x 8 SCU + 1x 4 SCU
# models = ScData::CargoFinder.find_fitting_models(container_set)



