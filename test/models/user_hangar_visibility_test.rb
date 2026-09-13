# frozen_string_literal: true

require "test_helper"

# `with_hangar_readable_by` is the bulk form of `Public::UserPolicy#show?`, used
# by the multi-hangar embed. It is the one visibility check that is a query
# rather than a predicate, so it is the one that can drift from the policy
# without any single-user path noticing.
class UserHangarVisibilityTest < ActiveSupport::TestCase
  setup do
    @reader = create(:user)
  end

  test "a public hangar is readable by anybody, signed in or not" do
    owner = create(:user, public_hangar: true)

    assert_includes User.with_hangar_readable_by(@reader), owner
    assert_includes User.with_hangar_readable_by(nil), owner
  end

  test "a closed hangar is readable by nobody" do
    owner = create(:user, public_hangar: false)

    assert_not_includes User.with_hangar_readable_by(@reader), owner
    assert_not_includes User.with_hangar_readable_by(nil), owner
  end

  test "a friends-only hangar is readable by a friend and by nobody else" do
    owner = create(:user, public_hangar: false, friends_hangar: true)
    create(:friendship, :accepted, requester: owner, addressee: @reader)

    assert_includes User.with_hangar_readable_by(@reader), owner
    assert_not_includes User.with_hangar_readable_by(create(:user)), owner
    assert_not_includes User.with_hangar_readable_by(nil), owner
  end

  test "the friendship has to be accepted" do
    owner = create(:user, public_hangar: false, friends_hangar: true)
    create(:friendship, requester: owner, addressee: @reader)

    assert_not_includes User.with_hangar_readable_by(@reader), owner
  end

  test "being a friend does not open a hangar whose friend switch is off" do
    owner = create(:user, public_hangar: false, friends_hangar: false)
    create(:friendship, :accepted, requester: owner, addressee: @reader)

    assert_not_includes User.with_hangar_readable_by(@reader), owner
  end

  test "it composes with the username filter the embed applies" do
    friend_owner = create(:user, public_hangar: false, friends_hangar: true)
    public_owner = create(:user, public_hangar: true)
    unlisted = create(:user, public_hangar: true)
    create(:friendship, :accepted, requester: friend_owner, addressee: @reader)

    result = User.where(normalized_username: [friend_owner, public_owner].map(&:normalized_username))
      .with_hangar_readable_by(@reader)

    assert_equal [friend_owner, public_owner].map(&:id).sort, result.pluck(:id).sort
    assert_not_includes result, unlisted
  end

  test "it agrees with the policy on every combination" do
    [true, false].product([true, false], [true, false]) do |(public_hangar, friends_hangar, befriended)|
      owner = create(:user, public_hangar:, friends_hangar:)
      create(:friendship, :accepted, requester: owner, addressee: @reader) if befriended

      scope_says = User.with_hangar_readable_by(@reader).exists?(owner.id)
      policy_says = Public::UserPolicy.new(owner, user: @reader).show?

      assert_equal policy_says, scope_says,
        "public=#{public_hangar} friends=#{friends_hangar} befriended=#{befriended}"
    end
  end
end
