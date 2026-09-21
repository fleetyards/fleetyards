# frozen_string_literal: true

require "test_helper"

module Maintenance
  class RepairIngameOnlyBoughtViaTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::RepairIngameOnlyBoughtViaTask.new
      @user = create(:user)
      @ingame_only = create(:model, ingame_only: true)
    end

    # The rows the task exists for are the ones written before the flag, so they
    # are made the way the database already holds them rather than through a
    # save the new callback would correct on the way in.
    def stale_vehicle(model)
      vehicle = create(:vehicle, user: @user, model:)
      vehicle.update_columns(bought_via: Vehicle.bought_via[:pledge_store])
      vehicle
    end

    test "#collection is the store-bought entries for in-game-only ships" do
      stale = stale_vehicle(@ingame_only)
      pledge_ship = create(:vehicle, user: @user, model: create(:model))

      ids = @task.collection.pluck(:id)

      assert_includes ids, stale.id
      assert_not_includes ids, pledge_ship.id
    end

    test "#collection leaves an entry that already says in-game alone" do
      create(:vehicle, user: @user, model: @ingame_only, bought_via: :ingame)

      assert_equal 0, @task.count
    end

    # The collection is walked in batches, so the flag can be cleared while the
    # run is still working through the rows it selected.
    test "#process leaves an entry alone once its ship is sold in the store again" do
      vehicle = stale_vehicle(@ingame_only)
      @ingame_only.update!(ingame_only: false)

      @task.process(vehicle.reload)

      assert vehicle.reload.bought_via_pledge_store?
    end

    test "#process records the entry as bought in game" do
      vehicle = stale_vehicle(@ingame_only)

      @task.process(vehicle)

      assert vehicle.reload.bought_via_ingame?
    end
  end
end
