# frozen_string_literal: true

require "test_helper"

class TourTest < ActiveSupport::TestCase
  test "requires a title" do
    assert_not Tour.new(created_by: create(:user)).valid?
  end

  test "prefixes the slug with the id so two tours can share a title" do
    first = create(:tour, title: "Jumptown Run")
    second = create(:tour, title: "Jumptown Run")

    assert_not_equal first.slug, second.slug
    assert first.slug.end_with?("jumptown-run")
    assert_equal first.id.split("-").first, first.slug.split("-").first
  end

  test "hands out an invite token on create" do
    assert_not_nil create(:tour).invite_token
  end

  test "rotating the invite token invalidates the old one" do
    tour = create(:tour)
    old = tour.invite_token

    tour.rotate_invite_token!

    assert_not_equal old, tour.reload.invite_token
  end

  test "moves through its lifecycle" do
    tour = create(:tour)

    assert_predicate tour, :open?
    tour.settle!
    assert_predicate tour, :settled?
    assert_not_nil tour.settled_at
    tour.reopen!
    assert_predicate tour, :open?
  end

  test "a cancelled tour drops out of the active scope" do
    tour = create(:tour)
    tour.cancel!

    assert_predicate tour, :cancelled?
    assert_not_includes Tour.active, tour
  end
end
