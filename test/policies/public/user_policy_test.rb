# frozen_string_literal: true

require "test_helper"

# public × friend-flag × friendship, per surface. The cell that matters most is
# "public on, friend flag off": a friend is a member of the public, so the
# friend column is simply not consulted there rather than contradicting it.
class Public::UserPolicyTest < ActiveSupport::TestCase
  SURFACES = {
    show?: %i[public_hangar friends_hangar],
    show_stats?: %i[public_hangar_stats friends_hangar_stats],
    wishlist?: %i[public_wishlist friends_wishlist]
  }.freeze

  setup do
    @owner = create(:user, public_hangar: false)
    @friend = create(:user)
    @stranger = create(:user)
    create(:friendship, :accepted, requester: @owner, addressee: @friend)
  end

  def allowed?(rule, reader)
    Public::UserPolicy.new(@owner, user: reader).public_send(rule)
  end

  test "with everything off nobody sees anything" do
    SURFACES.each_key do |rule|
      refute allowed?(rule, @friend), "#{rule} was open to a friend"
      refute allowed?(rule, @stranger), "#{rule} was open to a stranger"
      refute allowed?(rule, nil), "#{rule} was open to an anonymous reader"
    end
  end

  test "public opens a surface to everybody" do
    SURFACES.each do |rule, (public_column, _)|
      @owner.update!(public_column => true)

      assert allowed?(rule, @stranger), "#{rule} was closed to a stranger"
      assert allowed?(rule, nil), "#{rule} was closed to an anonymous reader"

      @owner.update!(public_column => false)
    end
  end

  test "the friend flag opens a surface to friends only" do
    SURFACES.each do |rule, (_, friend_column)|
      @owner.update!(friend_column => true)

      assert allowed?(rule, @friend), "#{rule} was closed to a friend"
      refute allowed?(rule, @stranger), "#{rule} was open to a stranger"
      refute allowed?(rule, nil), "#{rule} was open to an anonymous reader"

      @owner.update!(friend_column => false)
    end
  end

  test "public wins, and the friend flag being off changes nothing" do
    SURFACES.each do |rule, (public_column, friend_column)|
      @owner.update!(public_column => true, friend_column => false)

      assert allowed?(rule, @friend), "#{rule} was closed to a friend"
      assert allowed?(rule, @stranger), "#{rule} was closed to a stranger"

      @owner.update!(public_column => false)
    end
  end

  test "a pending friendship is not a friendship" do
    pending_friend = create(:user)
    create(:friendship, requester: @owner, addressee: pending_friend)

    SURFACES.each do |rule, (_, friend_column)|
      @owner.update!(friend_column => true)

      refute allowed?(rule, pending_friend), "#{rule} was open to a pending request"

      @owner.update!(friend_column => false)
    end
  end

  test "each surface has its own switch" do
    @owner.update!(friends_hangar: true)

    assert allowed?(:show?, @friend)
    refute allowed?(:show_stats?, @friend)
    refute allowed?(:wishlist?, @friend)
  end
end
