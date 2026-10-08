# frozen_string_literal: true

# One party's standing exception about another: let this one through, or turn
# this one away.
#
# The stance itself is a column on the party (`inventory_transfer_policy`).
# These are the exceptions to it, and the two compose into every arrangement
# worth having -- `everyone` plus denials is a blocklist, `nobody` plus
# allowances is an allowlist, `known` plus either covers the rest.
class InventoryTransferRule < ApplicationRecord
  EFFECTS = {allow: 0, deny: 1}.freeze

  enum :effect, EFFECTS

  belongs_to :user, optional: true
  belongs_to :fleet, optional: true
  belongs_to :subject_user, class_name: "User", optional: true
  belongs_to :subject_fleet, class_name: "Fleet", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validate :exactly_one_holder
  validate :exactly_one_subject
  validate :holder_is_not_the_subject

  def self.ransackable_attributes(_auth_object = nil)
    %w[effect created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  # Every rule a party holds, whichever kind of party it is.
  def self.held_by(party)
    case party
    when ::User then where(user: party)
    when ::Fleet then where(fleet: party)
    else none
    end
  end

  def self.about(party)
    case party
    when ::User then where(subject_user: party)
    when ::Fleet then where(subject_fleet: party)
    else none
    end
  end

  # The rule one party holds about another, or nothing.
  def self.between(holder:, subject:)
    held_by(holder).about(subject).first
  end

  def holder
    user || fleet
  end

  def holder=(party)
    self.user = party.is_a?(::User) ? party : nil
    self.fleet = party.is_a?(::Fleet) ? party : nil
  end

  def subject
    subject_user || subject_fleet
  end

  def subject=(party)
    self.subject_user = party.is_a?(::User) ? party : nil
    self.subject_fleet = party.is_a?(::Fleet) ? party : nil
  end

  private def exactly_one_holder
    return if [user, fleet].compact.one?

    errors.add(:base, :invalid_holder)
  end

  private def exactly_one_subject
    return if [subject_user, subject_fleet].compact.one?

    errors.add(:subject, :blank)
  end

  # A rule about yourself decides nothing: the gate never runs on a transfer you
  # could have made by hand.
  private def holder_is_not_the_subject
    return if holder.blank? || subject.blank?
    return unless holder == subject

    errors.add(:subject, :invalid)
  end
end
