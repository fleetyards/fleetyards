# frozen_string_literal: true

# The transfer endpoints, shared by the hangar and the fleet mount points.
#
# Which mount point you call decides the *sending party*; the payload decides
# the target. That is the only difference between the two, so the action bodies
# live here and each controller says only who it is acting for.
module InventoryTransferActions
  extend ActiveSupport::Concern
  include FleetInventoryScoped
  include InventoryTransfersFeatureConcern

  # `state_in` is declared as an array and has to be permitted as one: a scalar
  # permit silently drops a multi-state request, and the caller gets the whole
  # unfiltered list back rather than an error.
  QUERY_PARAMS = [:state_eq, :created_at_gteq, :created_at_lteq, :s, {state_in: []}].freeze

  included do
    after_action -> { pagination_header(:inventory_transfers) }, only: %i[index]
  end

  # The party this controller acts for: the signed-in user, or the fleet in the
  # path.
  private def acting_party
    raise NotImplementedError, "#{self.class.name} must define #acting_party"
  end

  def index
    authorize! with: InventoryTransferPolicy

    scope = case params[:direction]
    when "incoming" then incoming_scope
    when "outgoing" then outgoing_scope
    else incoming_scope.or(outgoing_scope)
    end

    query_params = params.fetch(:q, {}).permit(*QUERY_PARAMS)
    normalize_sort_params(query_params)
    query_params["sorts"] = sorting_params(InventoryTransfer, query_params["sorts"])

    @q = scope.ransack(query_params)

    @inventory_transfers = result_with_pagination(
      @q.result(distinct: true).includes(transfer_includes),
      per_page(InventoryTransfer)
    )
  end

  def show
    authorize! @inventory_transfer, with: InventoryTransferPolicy
  end

  def create
    authorize! with: InventoryTransferPolicy

    source = find_source
    return not_found if source.blank?
    return feature_closed unless inventory_feature_enabled?(source)

    contract = find_contract
    if transfer_params[:contract_id].present? && contract.blank?
      return render json: ValidationError.new("inventory_transfers.create",
        errors: contract_not_found_errors), status: :bad_request
    end

    # Both ends, not just the one the request came in through. An immediate
    # transfer never reaches `TransferGate`, which is what checks the recipient's
    # flags on the waiting path -- so without this a fleet officer could write
    # into their own hangar or ship inventory while that feature is switched
    # off, which is exactly the way round the new flag is not allowed to be.
    destination = find_destination(contract)
    return feature_closed if destination.present? && !inventory_feature_enabled?(destination)

    builder = ::Inventories::TransferBuilder.new(
      source:,
      actor: current_resource_owner,
      lines: transfer_params[:lines],
      destination:,
      recipient: find_recipient,
      note: transfer_params[:note],
      contract:
    )

    unless builder.call
      return render json: ValidationError.new("inventory_transfers.create", errors: builder.errors),
        status: :bad_request
    end

    @inventory_transfer = builder.transfer
    ::Inventories::TransferNotifier.new(@inventory_transfer).notify_sent

    render :show, status: :created
  end

  def accept
    authorize! @inventory_transfer, with: InventoryTransferPolicy

    # Passed unresolved on purpose: a ship inventory is provisioned by this
    # call, and that has to happen inside the resolver's transaction.
    destination = destination_resolver
    return not_found if destination.blank?

    resolve { |resolver| resolver.accept(destination) }
  end

  def decline
    authorize! @inventory_transfer, with: InventoryTransferPolicy

    resolve { |resolver| resolver.decline }
  end

  def cancel
    authorize! @inventory_transfer, with: InventoryTransferPolicy

    resolve { |resolver| resolver.cancel }
  end

  def report
    authorize! @inventory_transfer, with: InventoryTransferPolicy

    reporter = ::Inventories::TransferReporter.new(
      @inventory_transfer,
      actor: current_resource_owner,
      reason: params[:reason],
      note: params[:note]
    )

    unless reporter.call
      return render json: ValidationError.new("inventory_transfers.report", errors: reporter.errors),
        status: :bad_request
    end

    ::Inventories::TransferReportQueue.announce

    render :show
  end

  # Either an inventory that already exists, or something callable that brings
  # one into existence. Feature-gated here, before anything is written, because
  # the flag depends on which family the destination is in.
  private def destination_resolver
    if transfer_params[:vehicle_id].present?
      vehicle = current_resource_owner.vehicles.find_by(id: transfer_params[:vehicle_id])
      return if vehicle.blank?
      return unless feature_enabled?("ship_inventories")

      return -> { Inventory.provision_for(vehicle, holder: current_resource_owner) }
    end

    destination = find_destination
    return if destination.blank?
    return unless inventory_feature_enabled?(destination)

    destination
  end

  private def resolve
    resolver = ::Inventories::TransferResolver.new(@inventory_transfer, actor: current_resource_owner)

    unless yield(resolver)
      return render json: ValidationError.new("inventory_transfers.update", errors: resolver.errors),
        status: :bad_request
    end

    ::Inventories::TransferNotifier.new(@inventory_transfer).notify_resolved

    render :show
  end

  private def transfer_includes
    [:initiated_by, :recipient, :recipient_fleet,
      {source_inventory: :vehicle, destination_inventory: :vehicle,
       source_fleet_inventory: :fleet, destination_fleet_inventory: :fleet}]
  end

  # Every transfer this party has to answer, and every one it sent. Written as
  # two scopes over the party columns rather than over the inventories, so a
  # transfer whose far end was deleted still lists.
  #
  # Both are then narrowed to the inventories the reader may see -- see
  # `with_visible_fleet_ends`.
  # Addressed to this party, *or* delivered into one of its inventories. The
  # second half is not redundant: an immediate transfer names no recipient at
  # all, so a fleet issuing kit into a member's own locker matched neither this
  # nor `outgoing_scope` -- it showed on the fleet's list and was invisible to
  # the person who received it.
  private def incoming_scope
    case acting_party
    when ::Fleet
      with_visible_fleet_ends(
        InventoryTransfer
          .where(recipient_fleet: acting_party)
          .or(InventoryTransfer.where(destination_fleet_inventory: acting_party.fleet_inventories)),
        acting_party
      )
    else
      InventoryTransfer
        .where(recipient: acting_party)
        .or(InventoryTransfer.where(destination_inventory: acting_party.inventories))
    end
  end

  # A transfer names both of its ends, and the endpoint partial renders each
  # one's name and slug unconditionally. So an officers-only store leaks its
  # name through the list whichever end it sits at -- including a transfer
  # merely *addressed* to the fleet, which keeps its `recipient_fleet` when it
  # is accepted and so matches on that column whatever inventory it landed in.
  #
  # Only this fleet's hidden inventories are excluded. A far end belonging to
  # somebody else is not ours to judge, and filtering on "is visible" rather
  # than "is not hidden" would drop every cross-party transfer with it.
  private def with_visible_fleet_ends(relation, fleet)
    hidden = fleet.fleet_inventories.where.not(id: visible_fleet_inventories(fleet).select(:id)).pluck(:id)
    return relation if hidden.empty?

    # Spelled out rather than `where.not`: a NULL end is not "not in" the list,
    # it is unknown, so `NOT IN` would silently drop every transfer that has
    # only one end so far.
    relation
      .where("inventory_transfers.source_fleet_inventory_id IS NULL OR " \
             "inventory_transfers.source_fleet_inventory_id NOT IN (?)", hidden)
      .where("inventory_transfers.destination_fleet_inventory_id IS NULL OR " \
             "inventory_transfers.destination_fleet_inventory_id NOT IN (?)", hidden)
  end

  private def outgoing_scope
    case acting_party
    when ::Fleet
      with_visible_fleet_ends(
        InventoryTransfer.where(source_fleet_inventory: acting_party.fleet_inventories),
        acting_party
      )
    else
      InventoryTransfer.where(source_inventory: acting_party.inventories)
    end
  end

  private def transfer_params
    params.permit(:note, :inventory_id, :fleet_inventory_id, :vehicle_id,
      :recipient_username, :recipient_fleet_slug, :source_inventory_id, :contract_id,
      lines: [:position_id, :quantity])
  end

  # Both ends are resolved through the party this controller acts for, never by
  # id alone: naming an inventory somebody else holds is a 404 rather than a
  # hint that it exists.
  #
  # A user acting for themselves can still reach a *fleet* inventory here --
  # that is how a donation is accepted -- and whether they may actually write to
  # it is `TransferAuthorizer`'s question, asked afterwards.
  private def find_source
    resolve_own_inventory(transfer_params[:source_inventory_id])
  end

  # A *fleet* inventory is scoped to the party this mount acts for, so one
  # fleet cannot name another's. A *user* inventory is resolved against the
  # person making the request instead: a fleet issuing kit to one of its own
  # members is the sixth movement, and the member is often the one pressing the
  # button. Whether they may actually deposit there is `TransferAuthorizer`'s
  # question, asked by the builder straight after.
  #
  # This does not re-open the diversion hole review found: that was about
  # *accepting*, and `TransferResolver#accept` separately requires the
  # destination to belong to the transfer's recipient.
  #
  # The one inventory of somebody else's that can be named is the destination
  # of the contract the request is filed under, when that is the author's own.
  # It resolves only by matching that contract, so it says nothing about any
  # other inventory, and whether the actor may deliver there at all is
  # `Contracts::TransferLink`'s question.
  private def find_destination(contract = nil)
    resolve_actor_inventory(transfer_params[:inventory_id]) ||
      resolve_own_inventory(transfer_params[:fleet_inventory_id]) ||
      resolve_contract_destination(contract, transfer_params[:inventory_id])
  end

  private def resolve_contract_destination(contract, id)
    return if contract.blank? || id.blank?
    return unless contract.destination_inventory_id == id

    contract.destination_inventory
  end

  private def resolve_actor_inventory(id)
    return if id.blank?

    current_resource_owner.inventories.find_by(id:)
  end

  private def resolve_own_inventory(id)
    return if id.blank?

    inventories_for_party.find_by(id:)
  end

  private def inventories_for_party
    case acting_party
    when ::Fleet then acting_party.fleet_inventories
    else acting_party.inventories
    end
  end

  # Scoped to the fleets the caller is actually in, so naming a contract id
  # from a fleet they have nothing to do with is "no such contract" rather than
  # a hint that it exists. Whether they may *work* it is
  # `Contracts::TransferLink`'s question, asked by the builder.
  private def find_contract
    id = transfer_params[:contract_id]
    return if id.blank?
    return if current_resource_owner.blank?

    fleet_ids = current_resource_owner.fleet_memberships.kept.accepted.select(:fleet_id)

    ::FleetContract.where(fleet_id: fleet_ids).find_by(id:)
  end

  private def contract_not_found_errors
    errors = ::ActiveModel::Errors.new(::InventoryTransfer.new)
    errors.add(:base, :contract_not_found)
    errors
  end

  private def find_recipient
    if transfer_params[:recipient_username].present?
      User.find_by(normalized_username: transfer_params[:recipient_username].to_s.downcase)
    elsif transfer_params[:recipient_fleet_slug].present?
      Fleet.kept.find_by(slug: transfer_params[:recipient_fleet_slug])
    end
  end

  private def feature_closed
    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end

  # Scoped to the party this mount acts for, so a transfer can only be acted on
  # through one of its own ends. Without it an actor authorised for several
  # parties could answer a fleet-addressed transfer through their hangar, and
  # the side effects would be filed against the wrong one.
  private def set_inventory_transfer
    @inventory_transfer = incoming_scope.or(outgoing_scope).find(params[:id])
  end
end
