# frozen_string_literal: true

module TradeRoutes
  # How many SCU of cargo a ship can take on when a terminal only handles some
  # crate sizes.
  #
  # Each hold is filled with the single crate size that loads the most of it.
  # Mixing sizes can squeeze a little more into an awkward hold, but the
  # capacities we hold are measured one size at a time, so a mixed figure would
  # be a guess; this one is always achievable.
  class ShipCapacity
    def initialize(model)
      @holds = CargoHold
        .joins(sanitize("INNER JOIN models ON models.id = ?", model.id))
        .where(ScData::CargoFinderSql::CARGO_HOLDS_FOR_MODEL_SQL)
        .includes(:cargo_hold_container_capacities)
        .to_a
    end

    def scu_for(container_sizes)
      allowed = container_sizes.to_set

      @holds.sum do |hold|
        best = hold.cargo_hold_container_capacities
          .select { |capacity| allowed.include?(capacity.container_size_scu) }
          .map { |capacity| capacity.container_size_scu * capacity.max_quantity }
          .max || 0

        [best, hold.capacity_scu.to_i].min
      end
    end

    private def sanitize(sql, *values)
      ActiveRecord::Base.sanitize_sql_array([sql, *values])
    end
  end
end
