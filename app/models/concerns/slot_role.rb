# frozen_string_literal: true

# The seats a ship cannot do without, marked so they lead its list: the
# captain, then the pilot. A seat taken from a model's pilot position is the
# pilot without being told.
module SlotRole
  extend ActiveSupport::Concern

  ROLES = %w[captain pilot].freeze

  included do
    attr_readonly :role

    validates :role, inclusion: {in: ROLES}, allow_nil: true

    before_validation :take_role_from_position, on: :create

    # The team's lead first, then the captain and the pilot, then the rest in
    # the order they were arranged.
    default_scope lambda {
      order(lead: :desc)
        .order(Arel.sql("CASE #{table_name}.role WHEN 'captain' THEN 0 WHEN 'pilot' THEN 1 ELSE 2 END"))
        .order(position: :asc)
    }
  end

  def pilot?
    role == "pilot"
  end

  private def take_role_from_position
    self.role ||= "pilot" if model_position&.position_type == "pilot"
  end
end
