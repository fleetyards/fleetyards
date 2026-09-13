# frozen_string_literal: true

# A friendship answers to the two people in it and to nobody else, so most of
# this is one question asked five ways. The interesting part is that answering
# and calling back are *not* the same permission: only the side that was asked
# may answer, only the side that asked may call it back, and the model owns
# that distinction because `cancellable_by?` has to lie about an ignored row.
class FriendshipPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def show?
    involved?
  end

  def accept?
    record.answerable_by?(user)
  end

  def decline?
    accept?
  end

  def ignore?
    accept?
  end

  # One endpoint for two acts: calling back a request you sent, and ending a
  # friendship you are in. Which one it is follows from the state.
  def destroy?
    record.cancellable_by?(user) || (record.accepted? && involved?)
  end

  private def involved?
    record.involves?(user)
  end
end
