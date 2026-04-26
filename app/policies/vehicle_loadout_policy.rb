# frozen_string_literal: true

class VehicleLoadoutPolicy < ApplicationPolicy
  alias_rule :index?, :create?, to: :access?

  def access?
    user.present?
  end

  def manage?
    user&.id == record.vehicle.user_id
  end

  default_rule :manage?

  relation_scope do |relation|
    relation.joins(:vehicle).where(vehicles: {user_id: user.id})
  end
end
