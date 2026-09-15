# frozen_string_literal: true

class MissionPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:read"])
  end

  alias_rule :show?, to: :index?

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:create"])
  end

  def update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:update"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:delete"])
  end

  # Who may see a draft that is not theirs. `update` is in here because
  # `publish?` is aliased to it: somebody who may publish another author's draft
  # has to be able to find it first.
  def manage?
    accepted_fleet_membership&.has_access?(
      ["fleet:manage", "fleet:missions:manage", "fleet:missions:update"]
    )
  end

  alias_rule :publish?, to: :update?

  # Archiving happens through destroy, so restoring has to cost the same
  # privilege. Left on update? it would let someone with only
  # fleet:missions:update pull a mission back into the active list.
  alias_rule :unarchive?, to: :destroy?

  params_filter do |params|
    params.permit(:title, :description, :category, :scenario, :cover_image, :cover_image_preset)
  end
end
