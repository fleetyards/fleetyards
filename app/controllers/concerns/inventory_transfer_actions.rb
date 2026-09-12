# frozen_string_literal: true

# The transfer endpoints, shared by the hangar and the fleet mount points.
#
# Which mount point you call decides the *sending party*; the payload decides
# the target. That is the only difference between the two, so the action bodies
# live here and each controller says only who it is acting for.
module InventoryTransferActions
  extend ActiveSupport::Concern
  include InventoryTransfersFeatureConcern

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

    @inventory_transfers = result_with_pagination(
      scope.includes(transfer_includes).order(created_at: :desc),
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

    builder = ::Inventories::TransferBuilder.new(
      source:,
      actor: current_resource_owner,
      lines: transfer_params[:lines],
      destination: find_destination,
      recipient: find_recipient,
      note: transfer_params[:note]
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
  private def incoming_scope
    case acting_party
    when ::Fleet then InventoryTransfer.where(recipient_fleet: acting_party)
    else InventoryTransfer.where(recipient: acting_party)
    end
  end

  private def outgoing_scope
    case acting_party
    when ::Fleet
      InventoryTransfer.where(source_fleet_inventory: acting_party.fleet_inventories)
    else
      InventoryTransfer.where(source_inventory: acting_party.inventories)
    end
  end

  private def transfer_params
    params.permit(:note, :inventory_id, :fleet_inventory_id, :vehicle_id,
      :recipient_username, :recipient_fleet_slug, :source_inventory_id,
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

  private def find_destination
    resolve_own_inventory(transfer_params[:inventory_id]) ||
      resolve_own_inventory(transfer_params[:fleet_inventory_id])
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
