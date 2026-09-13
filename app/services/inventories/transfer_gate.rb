# frozen_string_literal: true

module Inventories
  # Whether a transfer a party has to *answer* may be sent to them at all.
  #
  # One ordered chain, first refusal wins. It runs exactly where the handshake
  # does: a transfer the initiator could have carried out by hand never reaches
  # here, because a deposit you are already allowed to make is not something a
  # policy can refuse. You cannot block yourself, and an officer depositing into
  # their own fleet is not "receiving" anything.
  #
  # Two of the refusals are deliberately not alike. A policy names itself --
  # "this fleet does not accept transfers" is an announced stance a sender can
  # act on. A denial does not: telling somebody they have been blocked is a
  # personal fact that invites retaliation and probing, so it answers with the
  # same message a closed policy would.
  class TransferGate
    Refusal = Struct.new(:code, :message)

    # An allowance overrides the stance and the cap -- it is how "nobody, except
    # these" is expressed, and how a trusted hauler stays reachable when an
    # inbox is full. It does not override a sanction, a missing flag or a
    # throttle: those are not the recipient's to waive.
    OVERRIDABLE = %i[policy cap].freeze

    def initialize(sender:, recipient:, actor: nil)
      @sender = sender
      @recipient = recipient
      @actor = actor
    end

    def allowed?
      refusal.nil?
    end

    def refusal
      return @refusal if defined?(@refusal)

      @refusal = CHECKS.lazy.filter_map { |check| send(check) }.first
    end

    CHECKS = %i[
      check_recipient_can_receive
      check_sender_not_sanctioned
      check_policy
      check_rule
      check_cap
    ].freeze

    # 1. The recipient can actually use the feature. Sending to somebody who can
    # never see it is worse than refusing: the goods would leave and sit until
    # they expired.
    private def check_recipient_can_receive
      return if recipient_feature_enabled?

      refuse(:unavailable)
    end

    # 2. A platform sanction on the sender, which an admin applies after
    # reviewing a report.
    private def check_sender_not_sanctioned
      return unless @sender.respond_to?(:transfers_blocked?) && @sender.transfers_blocked?

      refuse(:sender_blocked)
    end

    # 3. The recipient's stance. Named in the refusal, because it is announced.
    private def check_policy
      return if allowed_by_rule?
      return if policy_admits?

      refuse(@recipient.transfers_from_nobody? ? :policy_closed : :policy_restricted)
    end

    # 4. A standing denial about this sender. Answers as though the policy were
    # closed, on purpose.
    private def check_rule
      return unless rule&.deny?

      refuse(:policy_closed)
    end

    # 5. How much one recipient may have waiting at once.
    private def check_cap
      return if allowed_by_rule?
      return if outstanding_count < ::InventoryTransfer::OUTSTANDING_LIMIT

      refuse(:cap_reached)
    end

    private def refuse(code)
      Refusal.new(code:, message: I18n.t("inventory_transfers.refusals.#{code}"))
    end

    private def rule
      return @rule if defined?(@rule)

      @rule = @recipient.transfer_rule_about(@sender)
    end

    private def allowed_by_rule?
      rule&.allow?
    end

    private def policy_admits?
      case @recipient.inventory_transfer_policy
      when "everyone" then true
      when "known" then shares_a_fleet?
      else false
      end
    end

    # "Known" means there is already a relationship between the two parties: a
    # fleet in common for two users, membership for a user and a fleet.
    private def shares_a_fleet?
      case [@recipient, @sender]
      in [::User => recipient, ::User => sender]
        (fleet_ids_for(recipient) & fleet_ids_for(sender)).any?
      in [::User => recipient, ::Fleet => sender]
        fleet_ids_for(recipient).include?(sender.id)
      in [::Fleet => recipient, ::User => sender]
        fleet_ids_for(sender).include?(recipient.id)
      in [::Fleet => recipient, ::Fleet => sender]
        recipient == sender
      else
        false
      end
    end

    private def fleet_ids_for(user)
      @fleet_ids ||= {}
      @fleet_ids[user.id] ||= user.fleet_memberships.kept.accepted.pluck(:fleet_id)
    end

    private def outstanding_count
      case @recipient
      when ::User then ::InventoryTransfer.pending_for_user(@recipient).count
      when ::Fleet then ::InventoryTransfer.pending_for_fleet(@recipient).count
      else 0
      end
    end

    # Flipper is per-actor, so "is the feature on" has to be asked of the
    # recipient rather than of the request. A fleet is asked through the flag
    # its inventories already ride on.
    private def recipient_feature_enabled?
      return false unless Flipper.enabled?(:inventory_transfers, @recipient)

      case @recipient
      when ::User then Flipper.enabled?(:hangar_inventories, @recipient)
      when ::Fleet then Flipper.enabled?(:fleet_logistics, @recipient)
      else false
      end
    end
  end
end
