class OauthApplicationPolicy < ApplicationPolicy
  alias_rule :show?, :create?, :destroy?, :regenerate_secret?, to: :update?

  def index?
    user.present?
  end

  def update?
    user&.id == record.owner_id
  end

  relation_scope do |relation|
    relation.where(owner_id: user.id, owner_type: "User")
  end
end
