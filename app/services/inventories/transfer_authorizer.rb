# frozen_string_literal: true

module Inventories
  # The one question that decides whether a transfer needs a handshake:
  #
  #   > could the initiator have made this deposit themselves?
  #
  # If yes, the transfer is carried out on the spot. If no, it names a party and
  # waits for them. That rule -- rather than "same party is immediate, different
  # party waits" -- is what gets all six movements right. Moving cargo into a
  # fleet you are an officer of should not make you request and then approve
  # your own donation; shuffling stock between two fleet inventories should not
  # be open to a member with read-only access just because it stays in one
  # fleet.
  #
  # It also grants nobody anything new. Every immediate transfer is a write its
  # initiator could already have performed as a withdrawal followed by a
  # deposit; the transfer only makes it atomic and recorded as one event.
  class TransferAuthorizer
    def initialize(user)
      @user = user
    end

    # May this person take stock *out* of here? Always required, on every
    # transfer, because a transfer always starts with a withdrawal.
    def may_withdraw_from?(inventory)
      return false if @user.blank? || inventory.blank?

      case inventory
      when ::Inventory then inventory.holder == @user
      when ::FleetInventory then fleet_write_access?(inventory.fleet)
      else false
      end
    end

    # May this person put stock *into* here? The same question the gate asks,
    # and the answer that decides whether a handshake is needed.
    def may_deposit_into?(inventory)
      return false if @user.blank? || inventory.blank?

      case inventory
      when ::Inventory then inventory.holder == @user
      when ::FleetInventory then fleet_write_access?(inventory.fleet)
      else false
      end
    end

    # May this person answer a transfer addressed to this party -- accept it,
    # decline it, or report it?
    def may_answer_for?(party)
      return false if @user.blank? || party.blank?

      case party
      when ::User then party == @user
      when ::Fleet then fleet_write_access?(party)
      else false
      end
    end

    # The parties this person can send *as*: themselves, plus every fleet whose
    # inventories they may withdraw from.
    def sendable_parties
      return [] if @user.blank?

      [@user] + writable_fleets
    end

    private def writable_fleets
      return [] if @user.blank?

      @user.fleet_memberships.kept.accepted.includes(:fleet_role, :fleet).filter_map do |membership|
        membership.fleet if membership.has_access?(WRITE_PRIVILEGES)
      end
    end

    WRITE_PRIVILEGES = ["fleet:manage", "fleet:inventories:manage", "fleet:inventories:update"].freeze

    private def fleet_write_access?(fleet)
      return false if fleet.blank?

      membership_in(fleet)&.has_access?(WRITE_PRIVILEGES) || false
    end

    private def membership_in(fleet)
      @memberships ||= {}
      @memberships[fleet.id] ||= @user.fleet_memberships.kept.accepted.find_by(fleet:)
    end
  end
end
