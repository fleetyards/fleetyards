# frozen_string_literal: true

require "test_helper"

module Maintenance
  class BackfillVehicleRanksTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::BackfillVehicleRanksTask.new
      @user = create(:user)
    end

    def unrank(*vehicles)
      Vehicle.where(id: vehicles.map(&:id)).update_all(rank: nil)
    end

    def backfill
      @task.collection.find_each { @task.process(it) }
    end

    test "#collection is the owners with unranked vehicles" do
      unranked = create(:vehicle, user: @user)
      unrank(unranked)
      ranked_owner = create(:vehicle).user

      ids = @task.collection.pluck(:id)

      assert_includes ids, @user.id
      assert_not_includes ids, ranked_owner.id
    end

    test "ranks a hangar in its default order" do
      zeus = create(:vehicle, user: @user, name: nil, model: create(:model, name: "Zeus"))
      alpha = create(:vehicle, user: @user, name: "Alpha")
      flagship = create(:vehicle, user: @user, name: "Zulu", flagship: true)
      avenger = create(:vehicle, user: @user, name: nil, model: create(:model, name: "Avenger"))
      unrank(zeus, alpha, flagship, avenger)

      backfill

      assert_equal [flagship, alpha, avenger, zeus], @user.vehicles.ranked.to_a
    end

    test "ranks are fixed width and stay below z" do
      vehicles = create_list(:vehicle, 3, user: @user)
      unrank(*vehicles)

      backfill

      ranks = @user.vehicles.pluck(:rank)
      assert(ranks.all? { it.length == 4 && it < "z" })
    end

    test "a vehicle created afterwards goes to the end" do
      vehicles = create_list(:vehicle, 3, user: @user)
      unrank(*vehicles)
      backfill

      added = create(:vehicle, user: @user)

      assert_equal added, @user.vehicles.ranked.last
    end

    test "a hangar that already has ranks keeps them and gains the unranked at the end" do
      ranked = create(:vehicle, user: @user, name: "Zulu")
      late = create(:vehicle, user: @user, name: "Bravo")
      later = create(:vehicle, user: @user, name: "Charlie")
      unrank(late, later)

      backfill

      assert_equal "U", ranked.reload.rank
      assert_equal [ranked, late, later], @user.vehicles.ranked.to_a
    end

    test "a second run changes nothing" do
      vehicles = create_list(:vehicle, 3, user: @user)
      unrank(*vehicles)
      backfill

      assert_empty @task.collection
      assert_no_changes -> { @user.vehicles.order(:id).pluck(:rank) } do
        @task.process(@user)
      end
    end
  end
end
