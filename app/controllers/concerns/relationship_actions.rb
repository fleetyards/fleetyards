# frozen_string_literal: true

# The five things you can do to a relationship, for friendships and for fleet
# alliances alike. What differs between the two mount points is who is acting
# (a user, or a fleet a member is acting for) and how the other party is
# addressed (a username, or a slug), and those are the hooks.
#
# Listing goes through `in_state_for` rather than ransack, because the state a
# row is in and the state a party sees are not the same thing: a request the
# other side ignored is still pending to whoever sent it, and has to be listed
# that way as well as rendered that way.
module RelationshipActions
  extend ActiveSupport::Concern

  included do
    # The views need to know whose side they are rendering from: `state` and
    # `direction` are both answers about one of the two parties, not properties
    # of the row.
    #
    # A helper rather than a `before_action`: the concern's callbacks are
    # installed at `include` time, which is before the controller declares the
    # one that finds the fleet -- so an assignment here would run while the
    # acting party was still nil.
    helper_method :acting_party
  end

  STATES = %w[pending accepted declined ignored].freeze
  DIRECTIONS = %w[incoming outgoing].freeze

  def index
    authorize! relation_class, to: :index?, with: relationship_policy, **policy_context

    scope = relation_class.involving(acting_party)
      .in_state_for(requested_state, acting_party)
      .includes(:requester, :addressee)

    scope = scope.sent_by(acting_party) if requested_direction == "outgoing"
    scope = scope.received_by(acting_party) if requested_direction == "incoming"
    scope = narrow_relationships(scope)

    @relationships = result_with_pagination(scope.order(created_at: :desc), per_page(relation_class))
  end

  # The mount point's chance to narrow the list past state and direction.
  # Friendships have one -- the transfer picker asks for the friends it could
  # actually address -- and alliances do not.
  private def narrow_relationships(scope) = scope

  def show
  end

  def create
    authorize! relation_class, to: :create?, with: relationship_policy, **policy_context

    # A request that meets one from the other side accepts it, so this endpoint
    # can complete a relationship rather than only propose one. Accepting is the
    # consequential half -- for a fleet it commits the org's data -- and must not
    # be reachable with the create privilege alone.
    crossing = relation_class.between(acting_party, requested_party)

    if crossing&.pending? && crossing.addressee_id == acting_party.id
      authorize! crossing, to: :accept?, with: relationship_policy, **policy_context
    end

    requester = ::Relationships::Requester.new(relation_class, requester: acting_party, addressee: requested_party)

    unless requester.call
      render json: ValidationError.new("relationships.create", errors: requester.errors), status: :bad_request
      return
    end

    @relationship = requester.relationship
    render :show, status: :created
  end

  # The three answers, spelled out rather than generated. `ValidationErrorTest`
  # scans the app for literal `ValidationError.new("...")` codes and checks each
  # one is translated in every locale; a code built at runtime is invisible to
  # that scan and renders "translation missing" in production, which is the hole
  # the check exists to close.
  def accept
    answer(:accept) { |errors| ValidationError.new("relationships.accept", errors:) }
  end

  def decline
    answer(:decline) { |errors| ValidationError.new("relationships.decline", errors:) }
  end

  def ignore
    answer(:ignore) { |errors| ValidationError.new("relationships.ignore", errors:) }
  end

  # Calling back a request, or ending a relationship. One endpoint because from
  # the outside both are "remove this", and which one it is follows from the
  # state rather than from the caller having to know.
  def destroy
    answerer = ::Relationships::Answerer.new(@relationship, actor: current_resource_owner)
    outcome = @relationship.accepted? ? answerer.end_relationship(acting_party) : answerer.cancel(acting_party)

    return head :no_content if outcome

    render json: ValidationError.new("relationships.destroy", errors: answerer.errors), status: :bad_request
  end

  private def answer(event)
    answerer = ::Relationships::Answerer.new(@relationship, actor: current_resource_owner)

    unless answerer.public_send(event, acting_party)
      render json: yield(answerer.errors), status: :bad_request
      return
    end

    render :show
  end

  private def set_relationship
    @relationship = relation_class.between(acting_party, requested_party)

    raise ActiveRecord::RecordNotFound if @relationship.blank?

    # A request the sender withdrew is gone as far as they are concerned; the
    # row survives only to keep absorbing. Answering anything but 404 here would
    # tell them apart from a withdrawal that really did destroy the row.
    raise ActiveRecord::RecordNotFound if @relationship.withdrawn? &&
      @relationship.requester_id == acting_party&.id

    authorize! @relationship, to: :"#{action_name}?", with: relationship_policy, **policy_context
  end

  private def requested_state
    state = params[:state].presence || params.dig(:q, :state).presence

    STATES.include?(state) ? state : "accepted"
  end

  private def requested_direction
    direction = params[:direction].presence

    direction if DIRECTIONS.include?(direction)
  end

  private def policy_context
    {}
  end
end
