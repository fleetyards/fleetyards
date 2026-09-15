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

  # Who may see a draft that is not theirs. Publishing is not this: somebody
  # with `create` but not `manage` would be able to write a draft and never be
  # able to publish it, which is the whole of their job.
  def manage?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage"])
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
