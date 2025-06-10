class VehiclePolicy < ApplicationPolicy
  default_rule :manage?

  alias_rule :create_bulk?, :update_bulk?, :destroy_bulk?, :destroy_all_ingame?, to: :bulk?

  def check_serial?
    user.present?
  end

  def create?
    manage?
  end

  def manage?
    user&.id == record.user_id
  end

  def bulk?
    user.present?
  end

  relation_scope do |relation|
    relation.where(user_id: user.id)
  end
end
